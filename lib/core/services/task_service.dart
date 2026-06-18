import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:lms/core/models/task_model.dart';

/// Service responsible for fetching and streaming task data from Firestore.
///
/// Tasks can be stored in two locations:
/// 1. Top-level `tasks` collection (with `lectureId` or legacy `courseId` field)
/// 2. Nested `lectures/{lectureId}/tasks` subcollection
///
/// All query methods account for both storage patterns to ensure consistent results.
class TaskService {
  TaskService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Firestore `whereIn` queries are limited to 30 items per query.
  static const int _whereInChunkSize = 30;

  // ── Teacher: Stream all tasks ──────────────────────────────────────────────

  /// Streams all tasks from the top-level `tasks` collection.
  /// Used by teachers to see every task across all lectures.
  Stream<List<TaskModel>> streamAllTasks() {
    final query = _db.collection('tasks');
    return query.snapshots().map(_toSortedTaskList);
  }

  // ── Single Lecture: Stream tasks for one lecture ────────────────────────────

  /// Streams tasks for a specific lecture from all possible storage locations:
  /// 1. Top-level `tasks` where `lectureId == lectureId`
  /// 2. Top-level `tasks` where `courseId == lectureId` (legacy)
  /// 3. Nested `lectures/{lectureId}/tasks` subcollection
  ///
  /// Results are de-duplicated by `lectureId:taskId` key.
  Stream<List<TaskModel>> streamLectureTasks(String lectureId) {
    final topLevelByLecture = _db
        .collection('tasks')
        .where('lectureId', isEqualTo: lectureId);
    final topLevelLegacyByCourse = _db
        .collection('tasks')
        .where('courseId', isEqualTo: lectureId);
    final nestedTasks = _db
        .collection('lectures')
        .doc(lectureId)
        .collection('tasks');

    final topLevelLectureStream = topLevelByLecture.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
          .toList();
    });

    final topLevelCourseStream = topLevelLegacyByCourse.snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
          .toList();
    });

    final nestedTasksStream = nestedTasks.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        if ((data['lectureId'] as String?)?.trim().isEmpty ?? true) {
          return TaskModel.fromMap({...data, 'lectureId': lectureId}, doc.id);
        }
        return TaskModel.fromMap(data, doc.id);
      }).toList();
    });

    return _mergeTaskLists([
      topLevelLectureStream,
      topLevelCourseStream,
      nestedTasksStream,
    ]);
  }

  // ── Student: Stream tasks for multiple enrolled lectures ───────────────────

  /// Streams tasks for a set of lecture IDs the student has access to.
  ///
  /// Queries all possible storage locations:
  /// 1. Top-level `tasks` where `lectureId` in lectureIds (chunked for Firestore limit)
  /// 2. Top-level `tasks` where `courseId` in lectureIds (legacy, chunked)
  /// 3. Nested `lectures/{lectureId}/tasks` subcollection for each lecture
  ///
  /// Results are de-duplicated and sorted by deadline.
  Stream<List<TaskModel>> streamTasksForLectureIds(Set<String> lectureIds) {
    if (lectureIds.isEmpty) {
      return Stream.value(const <TaskModel>[]);
    }

    final idList = lectureIds.toList();
    final taskListStreams = <Stream<List<TaskModel>>>[];

    // ── 1. Top-level `tasks` collection queries (chunked for whereIn limit) ──
    final chunks = _chunkStrings(idList, _whereInChunkSize);
    for (final chunk in chunks) {
      // Query by `lectureId` field
      taskListStreams.add(
        _db
            .collection('tasks')
            .where('lectureId', whereIn: chunk)
            .snapshots()
            .map(
              (snapshot) => snapshot.docs
                  .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
                  .where((task) => task.lectureId.trim().isNotEmpty)
                  .toList(),
            ),
      );

      // Query by legacy `courseId` field
      taskListStreams.add(
        _db
            .collection('tasks')
            .where('courseId', whereIn: chunk)
            .snapshots()
            .map(
              (snapshot) => snapshot.docs
                  .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
                  .where((task) => task.lectureId.trim().isNotEmpty)
                  .toList(),
            ),
      );
    }

    // ── 2. Nested `lectures/{lectureId}/tasks` subcollection queries ──────────
    for (final lectureId in lectureIds) {
      taskListStreams.add(
        _db
            .collection('lectures')
            .doc(lectureId)
            .collection('tasks')
            .snapshots()
            .map(
              (snapshot) => snapshot.docs.map((doc) {
                final data = doc.data();
                // Ensure lectureId is set even if missing from subcollection doc
                if ((data['lectureId'] as String?)?.trim().isEmpty ?? true) {
                  return TaskModel.fromMap({
                    ...data,
                    'lectureId': lectureId,
                  }, doc.id);
                }
                return TaskModel.fromMap(data, doc.id);
              }).toList(),
            ),
      );
    }

    return _mergeTaskLists(taskListStreams);
  }

  // ── Student: Get all accessible lecture IDs ────────────────────────────────

  /// Resolves the complete set of lecture IDs a student has access to.
  ///
  /// Checks three sources:
  /// 1. `users/{uid}/progress` — lectures where progress has been tracked
  /// 2. `users/{uid}/enrolled_courses` — explicit enrollment records
  /// 3. `users/{uid}/purchases` — paid lecture/package purchases
  ///
  /// For package purchases, resolves the included lecture IDs from the
  /// `packages` collection.
  Future<Set<String>> getAccessibleLectureIdsForStudent(String userId) async {
    final progressFuture = _db
        .collection('users')
        .doc(userId)
        .collection('progress')
        .get();
    final enrolledFuture = _db
        .collection('users')
        .doc(userId)
        .collection('enrolled_courses')
        .get();
    final purchasesFuture = _db
        .collection('users')
        .doc(userId)
        .collection('purchases')
        .where('status', isEqualTo: 'active')
        .get();

    final results = await Future.wait<QuerySnapshot<Map<String, dynamic>>>([
      progressFuture,
      enrolledFuture,
      purchasesFuture,
    ]);

    final lectureIds = <String>{};
    final progressDocs = results[0];
    final enrolledDocs = results[1];
    final purchaseDocs = results[2];

    // Extract from progress docs (doc.id IS the lectureId)
    for (final doc in progressDocs.docs) {
      if (doc.id.isNotEmpty) {
        lectureIds.add(doc.id);
      }
      final dataLectureId = (doc.data()['lectureId'] as String?)?.trim() ?? '';
      if (dataLectureId.isNotEmpty) {
        lectureIds.add(dataLectureId);
      }
    }

    // Extract from enrolled_courses docs (doc.id IS the lectureId)
    for (final doc in enrolledDocs.docs) {
      if (doc.id.isNotEmpty) {
        lectureIds.add(doc.id);
      }
      final dataLectureId = (doc.data()['lectureId'] as String?)?.trim() ?? '';
      if (dataLectureId.isNotEmpty) {
        lectureIds.add(dataLectureId);
      }
      // Also check courseId field for legacy data
      final dataCourseId = (doc.data()['courseId'] as String?)?.trim() ?? '';
      if (dataCourseId.isNotEmpty) {
        lectureIds.add(dataCourseId);
      }
    }

    // Extract from purchases
    final purchasedPackageIds = <String>[];
    for (final purchaseDoc in purchaseDocs.docs) {
      final data = purchaseDoc.data();
      final itemType = (data['itemType'] as String?)?.toLowerCase().trim();
      final itemId = (data['itemId'] as String?)?.trim() ?? '';
      if (itemId.isEmpty) {
        continue;
      }

      if (itemType == 'lecture') {
        lectureIds.add(itemId);
      } else if (itemType == 'package') {
        purchasedPackageIds.add(itemId);
      }
    }

    // Resolve package → lecture IDs
    if (purchasedPackageIds.isNotEmpty) {
      final packageChunks = _chunkStrings(
        purchasedPackageIds,
        _whereInChunkSize,
      );
      for (final chunk in packageChunks) {
        final packageSnapshot = await _db
            .collection('packages')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final packageDoc in packageSnapshot.docs) {
          final includedLectureIds = List<String>.from(
            packageDoc.data()['includedLectureIds'] ?? const <String>[],
          );
          lectureIds.addAll(
            includedLectureIds.where((id) => id.trim().isNotEmpty),
          );
        }
      }
    }

    debugPrint(
      '[TaskService] Resolved ${lectureIds.length} accessible lecture IDs for student $userId',
    );
    return lectureIds;
  }

  // ── Fetch lecture title map (for Tasks page display) ───────────────────────

  /// Fetches lecture titles for the given IDs so tasks can display
  /// which lecture they belong to.
  Future<Map<String, String>> getLectureTitleMap(Set<String> lectureIds) async {
    if (lectureIds.isEmpty) return const {};

    final titleMap = <String, String>{};
    final chunks = _chunkStrings(lectureIds.toList(), _whereInChunkSize);

    for (final chunk in chunks) {
      final snapshot = await _db
          .collection('lectures')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final doc in snapshot.docs) {
        titleMap[doc.id] = (doc.data()['title'] as String?) ?? 'Untitled';
      }
    }

    return titleMap;
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  List<TaskModel> _toSortedTaskList(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final tasks = snapshot.docs
        .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
        .where((task) => task.lectureId.trim().isNotEmpty)
        .toList();
    tasks.sort((a, b) => a.deadline.compareTo(b.deadline));
    return tasks;
  }

  /// Merges multiple `Stream<List<TaskModel>>` into a single stream.
  /// De-duplicates tasks by `lectureId:taskId` composite key.
  Stream<List<TaskModel>> _mergeTaskLists(
    List<Stream<List<TaskModel>>> streams,
  ) {
    if (streams.isEmpty) {
      return Stream.value(const <TaskModel>[]);
    }

    late StreamController<List<TaskModel>> controller;
    final latestByStream = List<List<TaskModel>>.filled(streams.length, []);
    final subscriptions = <StreamSubscription<List<TaskModel>>>[];

    void emitMerged() {
      final mergedById = <String, TaskModel>{};
      for (final tasks in latestByStream) {
        for (final task in tasks) {
          if (task.lectureId.trim().isEmpty) {
            continue;
          }
          mergedById['${task.lectureId}:${task.id}'] = task;
        }
      }

      final merged = mergedById.values.toList()
        ..sort((a, b) => a.deadline.compareTo(b.deadline));
      if (!controller.isClosed) {
        controller.add(merged);
      }
    }

    controller = StreamController<List<TaskModel>>.broadcast(
      onListen: () {
        for (var i = 0; i < streams.length; i++) {
          final subscription = streams[i].listen(
            (tasks) {
              latestByStream[i] = tasks;
              emitMerged();
            },
            onError: (error, stackTrace) {
              debugPrint('[TaskService] Stream $i error: $error');
              latestByStream[i] = const [];
              emitMerged();
            },
          );
          subscriptions.add(subscription);
        }
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
        subscriptions.clear();
      },
    );

    return controller.stream;
  }

  /// Splits a list of strings into chunks of the given size.
  /// Required because Firestore `whereIn` is limited to 30 items.
  List<List<String>> _chunkStrings(List<String> values, int size) {
    if (values.isEmpty) {
      return const <List<String>>[];
    }

    final chunks = <List<String>>[];
    for (var i = 0; i < values.length; i += size) {
      final end = (i + size < values.length) ? i + size : values.length;
      chunks.add(values.sublist(i, end));
    }
    return chunks;
  }
}
