import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lms/core/providers/theme_provider.dart';
import 'package:lms/core/services/lecture_service.dart';
import 'package:lms/core/models/category_model.dart';
import 'package:lms/features/categories/screens/category_lectures_screen.dart';

// â”€â”€ Theme-aware color helper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _CategoryColors {
  final bool isDark;
  _CategoryColors(this.isDark);

  Color get bgColor1 =>
      isDark ? const Color(0xFF080510) : const Color(0xFFF8F5FF);
  Color get bgColor2 =>
      isDark ? const Color(0xFF150C2E) : const Color(0xFFEDE5FF);
  Color get bgColor3 =>
      isDark ? const Color(0xFF1A1242) : const Color(0xFFE0D4F7);
  Color get bgColor4 =>
      isDark ? const Color(0xFF0D0820) : const Color(0xFFF2EEFF);

  Color get cardBg => isDark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.white.withValues(alpha: 0.75);
  Color get cardBorder => isDark
      ? Colors.white.withValues(alpha: 0.10)
      : Colors.white.withValues(alpha: 0.9);

  Color get accentPrimary => const Color(0xFF7C3AED);
  Color get accentBright => const Color(0xFFA855F7);
  Color get accentPale =>
      isDark ? const Color(0xFFC084FC) : const Color(0xFF6D28D9);

  Color get textPrimary => isDark ? Colors.white : const Color(0xFF1A0845);
  Color get textSecondary =>
      isDark ? const Color(0xFFD4C5FF) : const Color(0xFF5B3D8F);

  List<BoxShadow> get cardShadow => isDark
      ? [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ]
      : [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ];

  double get orbOpacity => isDark ? 0.22 : 0.10;
}

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final LectureService _lectureService = LectureService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final c = _CategoryColors(isDark);

    return Scaffold(
      backgroundColor: c.bgColor1,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: _isSearching
            ? Container(
                height: 48,
                decoration: BoxDecoration(
                  color: c.cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: c.cardBorder, width: 1.5),
                  boxShadow: c.cardShadow,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(color: c.textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: "Search categories...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: c.textSecondary, fontSize: 14),
                  ),
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.toLowerCase()),
                ),
              )
            : Text(
                'Categories',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: c.textPrimary,
                ),
              ),
        leading: Container(
          margin: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
          decoration: BoxDecoration(
            color: c.cardBg,
            shape: BoxShape.circle,
            border: Border.all(color: c.cardBorder),
            boxShadow: c.cardShadow,
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: c.textPrimary,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 4, bottom: 4),
            decoration: BoxDecoration(
              color: c.cardBg,
              shape: BoxShape.circle,
              border: Border.all(color: c.cardBorder),
              boxShadow: c.cardShadow,
            ),
            child: IconButton(
              icon: Icon(
                _isSearching ? Icons.close : Icons.search,
                color: c.textPrimary,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _isSearching = false;
                    _searchQuery = "";
                    _searchController.clear();
                  } else {
                    _isSearching = true;
                  }
                });
              },
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // â”€â”€ Background Gradient â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c.bgColor1, c.bgColor2, c.bgColor3, c.bgColor4],
                  stops: const [0.0, 0.3, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // â”€â”€ Decorative Mesh Orbs â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7C3AED).withValues(alpha: c.orbOpacity),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 400,
            left: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(
                      0xFFA855F7,
                    ).withValues(alpha: c.orbOpacity * 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(
                      0xFF6D28D9,
                    ).withValues(alpha: c.orbOpacity * 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<List<CategoryModel>>(
                    stream: _lectureService.getCategoriesStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: c.accentPrimary,
                          ),
                        );
                      }

                      var categories = snapshot.data ?? [];
                      if (_searchQuery.isNotEmpty) {
                        categories = categories
                            .where(
                              (c) =>
                                  c.name.toLowerCase().contains(_searchQuery),
                            )
                            .toList();
                      }

                      if (categories.isEmpty) {
                        return Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'No categories found.'
                                : 'No matches found.',
                            style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.9,
                            ),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          return _buildCategoryCard(categories[index], c);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category, _CategoryColors c) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryLecturesScreen(
              categoryId: category.id,
              categoryName: category.name,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.cardBorder, width: 1.5),
          boxShadow: c.cardShadow,
        ),
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: c.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  "${category.lectureCount}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 36,
                    color: c.accentBright,
                    height: 1.0,
                  ),
                ),
                Text(
                  "Courses",
                  style: TextStyle(
                    fontSize: 13,
                    color: c.textSecondary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.videocam_outlined, "24+ Videos", c),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.picture_as_pdf_outlined, "45+ PDFs", c),
                const Spacer(),
              ],
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [c.accentPrimary, c.accentBright],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: c.accentPrimary.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, _CategoryColors c) {
    return Row(
      children: [
        Icon(icon, size: 16, color: c.textSecondary),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: c.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
