import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lms/core/providers/cart_provider.dart';
import 'package:lms/features/auth/providers/auth_provider.dart';
import 'package:lms/core/services/lecture_service.dart';
import 'package:lms/features/courses/screens/all_courses_screen.dart';
import 'package:lms/core/providers/theme_provider.dart';
import 'package:lms/core/providers/navigation_provider.dart';
import 'package:lms/core/services/payment_service.dart';

// ── Theme-aware color helper ─────────────────────────────────────────────────
class _CartColors {
  final bool isDark;
  _CartColors(this.isDark);

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

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _isCheckingOut = false;

  Future<void> _handleCheckout() async {
    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();
    final user = authProvider.userModel;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login to checkout')));
      return;
    }

    setState(() => _isCheckingOut = true);

    String fName = user.name;
    String lName = '';
    if (user.name.contains(' ')) {
      final parts = user.name.split(' ');
      fName = parts.first;
      lName = parts.sublist(1).join(' ');
    }

    final db = FirebaseFirestore.instance;
    final orderId = db.collection('orders').doc().id;
    final courseNames = cartProvider.items.map((e) => e.title).join(', ');

    PaymentService.startCoursePayment(
      context: context,
      orderId: orderId,
      courseName: courseNames,
      amount: cartProvider.totalPrice,
      currency: cartProvider.currency,
      customerFirstName: fName,
      customerLastName: lName,
      customerEmail: user.email,
      customerPhone: user.phoneNumber ?? '0000000000',
      customerAddress: 'N/A', // Update if address is added to user model
      customerCity: 'N/A',
      onCompleted: (paymentId) async {
        try {
          final lectureService = LectureService();
          final batch = db.batch();

          for (final item in cartProvider.items) {
            final purchaseRef = db
                .collection('users')
                .doc(user.uid)
                .collection('purchases')
                .doc();
            DateTime? expiresAt;
            if (item.itemType == 'lecture') {
              final doc = await db
                  .collection('lectures')
                  .doc(item.itemId)
                  .get();
              if (doc.exists && doc.data()?['isLifetime'] == false) {
                final days = doc.data()?['accessDurationDays'] ?? 0;
                if (days > 0)
                  expiresAt = DateTime.now().add(Duration(days: days));
              }
              await lectureService.enrollStudent(user.uid, item.itemId);
            } else if (item.itemType == 'package') {
              final doc = await db
                  .collection('packages')
                  .doc(item.itemId)
                  .get();
              if (doc.exists) {
                final data = doc.data()!;
                if (data['isLifetime'] == false) {
                  final days = data['accessDurationDays'] ?? 0;
                  if (days > 0)
                    expiresAt = DateTime.now().add(Duration(days: days));
                }
                final List<dynamic> includedIds =
                    data['includedLectureIds'] ?? [];
                for (final lId in includedIds) {
                  await lectureService.enrollStudent(user.uid, lId.toString());
                }
              }
            }
            batch.set(purchaseRef, {
              'id': purchaseRef.id,
              'itemId': item.itemId,
              'itemType': item.itemType,
              'purchasedAt': FieldValue.serverTimestamp(),
              'expiresAt': expiresAt != null
                  ? Timestamp.fromDate(expiresAt)
                  : null,
              'status': 'active',
              'paymentId': paymentId,
            });
          }

          await batch.commit();
          await cartProvider.clearCart();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Checkout successful! You are now enrolled.'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Verification failed: $e'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isCheckingOut = false);
        }
      },
      onError: () {
        if (mounted) setState(() => _isCheckingOut = false);
      },
      onCanceled: () {
        if (mounted) setState(() => _isCheckingOut = false);
      },
    );
  }

  Widget _buildBackground(_CartColors c) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
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
                  const Color(0xFFA855F7).withValues(alpha: c.orbOpacity * 0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final items = cartProvider.items;
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final c = _CartColors(isDark);

    return Scaffold(
      backgroundColor: c.bgColor1,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildBackground(c),
          SafeArea(
            bottom: false,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back_ios_new,
                              color: c.textSecondary,
                              size: 20,
                            ),
                            padding: const EdgeInsets.only(left: 8, right: 12),
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              try {
                                context.read<NavigationProvider>().setIndex(0);
                              } catch (e) {
                                Navigator.pop(context);
                              }
                            },
                          ),
                          Text(
                            'Your Cart',
                            style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? _buildEmptyCart(context, c)
                      : _buildCartList(context, cartProvider, c),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: items.isEmpty
          ? const SizedBox.shrink()
          : _buildCheckoutBottomBar(context, cartProvider, c),
    );
  }

  Widget _buildEmptyCart(BuildContext context, _CartColors c) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: c.cardBorder, width: 1.5),
          boxShadow: c.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.accentPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: c.accentPale,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your cart is empty',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Looks like you haven\'t added\nany courses to your cart yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AllCoursesScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.accentPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ), // Smaller padding than before
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Browse Courses',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartList(
    BuildContext context,
    CartProvider cartProvider,
    _CartColors c,
  ) {
    final items = cartProvider.items;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: c.cardBorder, width: 1.5),
            boxShadow: c.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    item.thumbnailUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 72,
                        height: 72,
                        color: c.accentPrimary.withValues(alpha: 0.2),
                        child: Icon(
                          Icons.play_circle_outline,
                          color: c.accentPale,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: c.accentPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.itemType.toUpperCase(),
                          style: TextStyle(
                            color: c.accentPale,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${cartProvider.currency == 'LKR' ? 'Rs. ' : '\$'}${cartProvider.getItemPrice(item.price).toStringAsFixed(2)}',
                            style: TextStyle(
                              color: c.accentPale,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                cartProvider.removeFromCart(item.itemId),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckoutBottomBar(
    BuildContext context,
    CartProvider cartProvider,
    _CartColors c,
  ) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: c.isDark
            ? const Color(0xFF150C2E).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: c.cardBorder, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: c.isDark
                ? Colors.black.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total:',
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  '${cartProvider.currency == 'LKR' ? 'Rs. ' : '\$'}${cartProvider.totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isCheckingOut ? null : _handleCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: c.accentPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: _isCheckingOut
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Proceed to Checkout',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
