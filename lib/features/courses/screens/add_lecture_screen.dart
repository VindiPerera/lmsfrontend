import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lms/core/models/lecture_model.dart';
import 'package:lms/core/models/category_model.dart';
import 'package:lms/core/services/lecture_service.dart';
import 'package:lms/core/services/file_upload_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddLectureScreen extends StatefulWidget {
  final LectureModel? existingLecture;

  const AddLectureScreen({Key? key, this.existingLecture}) : super(key: key);

  @override
  _AddLectureScreenState createState() => _AddLectureScreenState();
}

class _AddLectureScreenState extends State<AddLectureScreen> {
  final _formKey = GlobalKey<FormState>();
  final LectureService _lectureService = LectureService();
  final FileUploadService _fileUploadService = FileUploadService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _durationDaysController =
      TextEditingController(); // Days access
  final TextEditingController _durationStringController =
      TextEditingController(); // "6h 30m"
  final TextEditingController _lessonCountController =
      TextEditingController(); // "5 Lessons"
  final TextEditingController _newCategoryController = TextEditingController();

  List<TextEditingController> _lessonsControllers = [];
  List<TextEditingController> _resourcesControllers = [];
  List<Map<String, dynamic>> _tasks = [];
  List<String> _tasksToDelete = [];

  String? _selectedCategoryId;
  String? _selectedCategoryName;
  bool _isPaid = false;
  bool _isLifetime = true;
  String _visibility = 'published'; // 'published', 'private', 'scheduled'
  DateTime? _scheduledDate;

  File? _thumbnailFile;
  String? _thumbnailUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingLecture != null) {
      final l = widget.existingLecture!;
      _titleController.text = l.title;
      _priceController.text = l.price.toString();
      _isLifetime = l.accessDurationDays == null || l.accessDurationDays == 0;
      _durationDaysController.text = l.accessDurationDays?.toString() ?? '';
      _durationStringController.text = l.durationString;

      // If lessonCount is stored separately (e.g. meta field), use it.
      // Otherwise default to list length if 0.
      _lessonCountController.text = l.lessons.length.toString();

      _selectedCategoryId = l.categoryId;
      _selectedCategoryName = l.categoryName;
      _isPaid = l.isPaid;
      _visibility = l.visibility;
      _scheduledDate = l.scheduledDate;
      _thumbnailUrl = l.thumbnailUrl;

      for (var lesson in l.lessons) {
        _lessonsControllers.add(TextEditingController(text: lesson));
      }
      for (var resource in l.resources) {
        _resourcesControllers.add(TextEditingController(text: resource));
      }
      _fetchTasks(l.id);
    } else {
      _lessonsControllers.add(TextEditingController());
      _resourcesControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _durationDaysController.dispose();
    _durationStringController.dispose();
    _durationStringController.dispose();
    _lessonCountController.dispose();
    _newCategoryController.dispose();
    for (var c in _lessonsControllers) {
      c.dispose();
    }
    for (var c in _resourcesControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchTasks(String lectureId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('lectureId', isEqualTo: lectureId)
        .get();
    if (mounted) {
      setState(() {
        _tasks = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'] ?? '',
            'pdfLink': data['pdfLink'] ?? '',
            'deadline':
                (data['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
          };
        }).toList();
      });
    }
  }

  Future<void> _pickImage() async {
    final file = await _fileUploadService.pickImage();
    if (file != null) {
      setState(() {
        _thumbnailFile = file;
      });
    }
  }

  Future<void> _pickScheduledDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _scheduledDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _addNewCategory() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Category'),
          content: TextField(
            controller: _newCategoryController,
            decoration: const InputDecoration(hintText: 'Category Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = _newCategoryController.text.trim();
                if (name.isNotEmpty) {
                  final id = FirebaseFirestore.instance
                      .collection('categories')
                      .doc()
                      .id;
                  final category = CategoryModel(id: id, name: name);
                  await _lectureService.createCategory(category);
                  setState(() {
                    _selectedCategoryId = id;
                    _selectedCategoryName = name;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddTaskDialog([
    Map<String, dynamic>? existingTask,
    int? index,
  ]) async {
    final titleController = TextEditingController(
      text: existingTask?['title'] ?? '',
    );
    final pdfLinkController = TextEditingController(
      text: existingTask?['pdfLink'] ?? '',
    );
    DateTime selectedDeadline =
        existingTask?['deadline'] ??
        DateTime.now().add(const Duration(days: 7));

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existingTask == null ? 'Add Task' : 'Edit Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Task Title',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: pdfLinkController,
                      decoration: const InputDecoration(
                        labelText: 'PDF/Assignment Link',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Deadline: ${DateFormat('yyyy-MM-dd HH:mm').format(selectedDeadline)}',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDeadline,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(
                                  selectedDeadline,
                                ),
                              );
                              if (time != null) {
                                setDialogState(() {
                                  selectedDeadline = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newTask = {
                      'id': existingTask?['id'], // keep original id if editing
                      'title': titleController.text.trim(),
                      'pdfLink': pdfLinkController.text.trim(),
                      'deadline': selectedDeadline,
                    };
                    setState(() {
                      if (index != null) {
                        _tasks[index] = newTask;
                      } else {
                        _tasks.add(newTask);
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveLecture() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }
    if (_thumbnailFile == null && _thumbnailUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a thumbnail')),
      );
      return;
    }
    if (_visibility == 'scheduled' && _scheduledDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a scheduled date')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String finalThumbnailUrl = _thumbnailUrl ?? '';
      if (_thumbnailFile != null) {
        final url = await _fileUploadService.uploadFile(
          _thumbnailFile!,
          folderType: 'thumbnails',
        );
        if (url != null) {
          finalThumbnailUrl = url;
        } else {
          throw Exception('Failed to upload thumbnail');
        }
      }

      final List<String> lessons = _lessonsControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      final List<String> resources = _resourcesControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final lectureId =
          widget.existingLecture?.id ??
          FirebaseFirestore.instance.collection('lectures').doc().id;

      final lecture = LectureModel(
        id: lectureId,
        title: _titleController.text.trim(),
        categoryId: _selectedCategoryId!,
        categoryName: _selectedCategoryName!,
        thumbnailUrl: finalThumbnailUrl,
        lessons: lessons,
        resources: resources,
        isPaid: _isPaid,
        price: _isPaid ? double.tryParse(_priceController.text) ?? 0.0 : 0.0,
        accessDurationDays: _isPaid && !_isLifetime
            ? (int.tryParse(_durationDaysController.text) ?? 0)
            : null,
        visibility: _visibility,
        scheduledDate: _visibility == 'scheduled' ? _scheduledDate : null,
        enrolledCount: widget.existingLecture?.enrolledCount ?? 0,
        durationString: _durationStringController.text.trim(),
        // Use manually entered count or fallback to list length
        reviewCount: widget.existingLecture?.reviewCount ?? 0,
        averageRating: widget.existingLecture?.averageRating ?? 0.0,
        createdAt: widget.existingLecture?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.existingLecture == null) {
        await _lectureService.createLecture(lecture);
      } else {
        await _lectureService.updateLecture(lecture);
      }

      final batch = FirebaseFirestore.instance.batch();
      for (String id in _tasksToDelete) {
        batch.delete(FirebaseFirestore.instance.collection('tasks').doc(id));
      }
      for (var task in _tasks) {
        final docRef = task['id'] != null
            ? FirebaseFirestore.instance.collection('tasks').doc(task['id'])
            : FirebaseFirestore.instance.collection('tasks').doc();
        batch.set(docRef, {
          'lectureId': lectureId,
          'title': task['title'],
          'pdfLink': task['pdfLink'],
          'deadline': Timestamp.fromDate(task['deadline']),
          'createdAt': task['id'] != null
              ? FieldValue.serverTimestamp()
              : FieldValue.serverTimestamp(), // Just merge
        }, SetOptions(merge: true));
      }
      await batch.commit();

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving course: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteLecture() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Course'),
        content: const Text(
          'Are you sure you want to delete this course? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && widget.existingLecture != null) {
      setState(() => _isLoading = true);
      try {
        await _lectureService.deleteLecture(widget.existingLecture!);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
        }
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteCategory() async {
    if (_selectedCategoryId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete category "$_selectedCategoryName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _lectureService.deleteCategory(_selectedCategoryId!);
        setState(() {
          _selectedCategoryId = null;
          _selectedCategoryName = null;
        });
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Category deleted')));
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingLecture == null ? 'Add Course' : 'Edit Course',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Thumbnail Picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: _thumbnailFile != null
                            ? Image.file(_thumbnailFile!, fit: BoxFit.cover)
                            : _thumbnailUrl != null
                            ? Image.network(_thumbnailUrl!, fit: BoxFit.cover)
                            : const Center(
                                child: Icon(
                                  Icons.add_a_photo,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Course Title',
                      ),
                      validator: (val) => val!.isEmpty ? 'Enter a title' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _durationDaysController,
                            decoration: const InputDecoration(
                              labelText: 'Access Days (0 = Lifetime)',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _durationStringController,
                            decoration: const InputDecoration(
                              labelText: 'Duration (e.g. 6h 30m)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Lesson Count input (Optional, as lessons list length can be used)
                    TextFormField(
                      controller: _lessonCountController,
                      decoration: const InputDecoration(
                        labelText: 'Lesson Count to Display (e.g. 10)',
                        helperText:
                            'Leave empty to auto-count from added lessons below',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    Row(
                      children: [
                        Expanded(
                          child: StreamBuilder<List<CategoryModel>>(
                            stream: _lectureService.getCategoriesStream(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData)
                                return const CircularProgressIndicator();
                              final categories = snapshot.data!;
                              final hasValidCategory = categories.any(
                                (c) => c.id == _selectedCategoryId,
                              );
                              return DropdownButtonFormField<String>(
                                value: hasValidCategory
                                    ? _selectedCategoryId
                                    : null,
                                decoration: const InputDecoration(
                                  labelText: 'Category',
                                ),
                                items: categories.map((c) {
                                  return DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedCategoryId = val;
                                    _selectedCategoryName = categories
                                        .firstWhere((c) => c.id == val)
                                        .name;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        if (_selectedCategoryId != null)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: _deleteCategory,
                            tooltip: 'Delete Selected Category',
                          ),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          onPressed: _addNewCategory,
                          tooltip: 'Add New Category',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Pricing
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Is this a Paid Course?',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: _isPaid
                          ? null
                          : const Text(
                              'Check to set a price',
                              style: TextStyle(color: Colors.grey),
                            ),
                      value: _isPaid,
                      onChanged: (val) {
                        setState(() => _isPaid = val ?? false);
                      },
                    ),
                    if (_isPaid) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          hintText: 'e.g. 49.99',
                          prefixIcon: Icon(Icons.attach_money),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (val) =>
                            val!.isEmpty ? 'Enter a price' : null,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: SwitchListTile(
                          title: const Text(
                            'Lifetime Access',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text(
                            'Learners keep this course forever',
                          ),
                          value: _isLifetime,
                          activeColor: Theme.of(context).primaryColor,
                          onChanged: (val) {
                            setState(() => _isLifetime = val);
                          },
                        ),
                      ),
                      if (!_isLifetime) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _durationDaysController,
                          decoration: const InputDecoration(
                            labelText: 'Limited Duration (Days)',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (val) =>
                              val!.isEmpty ? 'Enter duration in days' : null,
                        ),
                      ],
                    ],
                    const SizedBox(height: 16),

                    // Visibility
                    DropdownButtonFormField<String>(
                      value: _visibility,
                      decoration: const InputDecoration(
                        labelText: 'Visibility',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'published',
                          child: Text('Published'),
                        ),
                        DropdownMenuItem(
                          value: 'private',
                          child: Text('Private'),
                        ),
                        DropdownMenuItem(
                          value: 'scheduled',
                          child: Text('Scheduled'),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _visibility = val!;
                        });
                      },
                    ),
                    if (_visibility == 'scheduled') ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _scheduledDate == null
                                  ? 'No Date Selected'
                                  : 'Scheduled: ${_scheduledDate.toString()}',
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _pickScheduledDate,
                            child: const Text('Pick Date/Time'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Lessons
                    const Text(
                      'Lessons (Drive/Video Links)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ..._lessonsControllers.asMap().entries.map((e) {
                      return Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: e.value,
                              decoration: InputDecoration(
                                labelText: 'Lesson ${e.key + 1} Link',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              setState(() {
                                _lessonsControllers[e.key].dispose();
                                _lessonsControllers.removeAt(e.key);
                              });
                            },
                          ),
                        ],
                      );
                    }).toList(),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _lessonsControllers.add(TextEditingController());
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Lesson'),
                    ),
                    const SizedBox(height: 16),

                    // Resources
                    const Text(
                      'Resources (PDF/Drive Links)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ..._resourcesControllers.asMap().entries.map((e) {
                      return Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: e.value,
                              decoration: InputDecoration(
                                labelText: 'Resource ${e.key + 1} Link',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              setState(() {
                                _resourcesControllers[e.key].dispose();
                                _resourcesControllers.removeAt(e.key);
                              });
                            },
                          ),
                        ],
                      );
                    }).toList(),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _resourcesControllers.add(TextEditingController());
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Resource'),
                    ),
                    const SizedBox(height: 24),

                    // Tasks
                    const Text(
                      'Tasks (Assignments)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ..._tasks.asMap().entries.map((e) {
                      final task = e.value;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(task['title']),
                        subtitle: Text(
                          'Due: ${DateFormat('yyyy-MM-dd HH:mm').format(task['deadline'])}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showAddTaskDialog(task, e.key),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (task['id'] != null) {
                                    _tasksToDelete.add(task['id']);
                                  }
                                  _tasks.removeAt(e.key);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    TextButton.icon(
                      onPressed: () => _showAddTaskDialog(),
                      icon: const Icon(Icons.add_task),
                      label: const Text('Add Task'),
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _saveLecture,
                      child: const Text(
                        'Save Course',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (widget.existingLecture != null)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _deleteLecture,
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Delete Course'),
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
