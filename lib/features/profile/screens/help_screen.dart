import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:lms/core/providers/theme_provider.dart';
import 'package:intl/intl.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final cBg = isDark ? const Color(0xFF080510) : const Color(0xFFF8F5FF);
    final cCardBg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.75);
    final cBorder = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.9);
    final cTextPrimary = isDark ? Colors.white : const Color(0xFF1A0845);
    final cTextSecondary = isDark
        ? const Color(0xFFD4C5FF)
        : const Color(0xFF5B3D8F);
    final cAccent = const Color(0xFF7C3AED);

    return Scaffold(
      backgroundColor: cBg,
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('app_settings')
              .doc('help')
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: cAccent));
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error fetching help information.",
                  style: TextStyle(color: cTextPrimary),
                ),
              );
            }

            final data = snapshot.data?.data() as Map<String, dynamic>?;
            final helpText =
                data?['help_content'] ??
                'No help information available at the moment.';
            final faqText =
                data?['faq_content'] ??
                'No FAQs available at the moment.';

            Timestamp? updatedTimestamp = data?['updated_at'] as Timestamp?;
            String updatedDateStr = updatedTimestamp != null
                ? DateFormat('MMMM dd, yyyy').format(updatedTimestamp.toDate())
                : 'Not available';

            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 8,
                      right: 24,
                      top: 12,
                      bottom: 12,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            color: cTextSecondary,
                            size: 20,
                          ),
                          padding: const EdgeInsets.only(left: 8, right: 12),
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          'Help & Support',
                          style: TextStyle(
                            color: cTextPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TabBar(
                    labelColor: cAccent,
                    unselectedLabelColor: cTextSecondary,
                    indicatorColor: cAccent,
                    tabs: const [
                      Tab(text: 'Help & Support'),
                      Tab(text: 'FAQs'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildContentTab(
                          helpText,
                          updatedDateStr,
                          cCardBg,
                          cBorder,
                          cTextPrimary,
                          cTextSecondary,
                        ),
                        _buildContentTab(
                          faqText,
                          updatedDateStr,
                          cCardBg,
                          cBorder,
                          cTextPrimary,
                          cTextSecondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContentTab(
    String content,
    String updateDate,
    Color bg,
    Color border,
    Color text,
    Color secondary,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: border)),
            ),
            child: Row(
              children: [
                Icon(Icons.update, size: 16, color: secondary),
                const SizedBox(width: 8),
                Text(
                  'Last Updated: $updateDate',
                  style: TextStyle(
                    fontSize: 12,
                    color: secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Text(
                content,
                style: TextStyle(color: text, fontSize: 15, height: 1.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
