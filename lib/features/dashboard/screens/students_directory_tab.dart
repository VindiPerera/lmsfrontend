import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lms/core/constants/app_text_styles.dart';

/// A widget that displays a searchable list of students.
/// Designed to work inside a SingleChildScrollView (no Expanded usage).
class StudentsDirectoryTab extends StatefulWidget {
  final dynamic c;
  const StudentsDirectoryTab({super.key, required this.c});

  @override
  State<StudentsDirectoryTab> createState() => _StudentsDirectoryTabState();
}

class _StudentsDirectoryTabState extends State<StudentsDirectoryTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'Students Directory',
          style: AppTextStyles.heading2.copyWith(color: c.textPrimary),
        ),
        const SizedBox(height: 16),

        // Search Bar
        TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
          style: TextStyle(color: c.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search by name or student ID...',
            hintStyle: TextStyle(color: c.textHint),
            prefixIcon: Icon(Icons.search, color: c.textHint),
            filled: true,
            fillColor: c.cardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c.accentPrimary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Students List — uses shrinkWrap so it works inside SingleChildScrollView
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'student')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('Error loading students.', style: TextStyle(color: c.textPrimary)),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: c.accentPrimary),
                ),
              );
            }

            final docs = snapshot.data!.docs;

            // Filter by search query — matches name or studentId
            final filteredDocs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['name'] ?? '').toString().toLowerCase();
              final studentId = (data['studentId'] ?? data['student_id'] ?? '').toString().toLowerCase();
              final email = (data['email'] ?? '').toString().toLowerCase();
              return _searchQuery.isEmpty ||
                  name.contains(_searchQuery) ||
                  studentId.contains(_searchQuery) ||
                  email.contains(_searchQuery);
            }).toList();

            // Total count badge
            final totalStudents = docs.length;
            final showing = filteredDocs.length;

            if (docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: c.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.cardBorder),
                ),
                child: Column(
                  children: [
                    Icon(Icons.people_outline, color: c.textHint, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'No students registered yet.',
                      style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Count indicator
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: c.accentPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _searchQuery.isEmpty
                              ? '$totalStudents students'
                              : '$showing of $totalStudents students',
                          style: TextStyle(
                            color: c.accentPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (filteredDocs.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: c.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.cardBorder),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.search_off, color: c.textHint, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'No students match your search.',
                          style: TextStyle(color: c.textSecondary, fontSize: 15),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredDocs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final data = filteredDocs[index].data() as Map<String, dynamic>;
                      final name = data['name'] ?? 'Unknown';
                      final email = data['email'] ?? 'No email';
                      final studentId = data['studentId'] ?? data['student_id'] ?? filteredDocs[index].id;
                      final avatarUrl = data['profile_image_url'] ?? '';

                      return Container(
                        decoration: BoxDecoration(
                          color: c.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.cardBorder),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: c.accentPrimary.withValues(alpha: 0.1),
                            backgroundImage: (avatarUrl is String && avatarUrl.isNotEmpty)
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: (avatarUrl is! String || avatarUrl.isEmpty)
                                ? Icon(Icons.person, color: c.accentPrimary)
                                : null,
                          ),
                          title: Text(
                            name,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.badge_outlined, size: 14, color: c.accentPrimary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'ID: $studentId',
                                      style: TextStyle(
                                        color: c.accentPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.email_outlined, size: 14, color: c.textHint),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      email,
                                      style: TextStyle(color: c.textSecondary, fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
