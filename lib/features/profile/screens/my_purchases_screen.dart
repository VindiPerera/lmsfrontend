import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lms/core/services/course_access_service.dart';
import 'package:lms/core/models/purchase_model.dart';
import 'package:lms/features/auth/providers/auth_provider.dart';

class MyPurchasesScreen extends StatelessWidget {
  const MyPurchasesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().userModel?.uid;
    if (userId == null)
      return const Scaffold(body: Center(child: Text('Not logged in')));

    final CourseAccessService accessService = CourseAccessService();

    return Scaffold(
      backgroundColor: const Color(0xFF864AFF),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFE5D9F2),
                    Color(0xFFD6C3FF),
                    Color(0xFFA573FF),
                    Color(0xFF8841FF),
                  ],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Color(0xFF38106A),
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'My Purchases',
                        style: TextStyle(
                          color: Color(0xFF280A54),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<PurchaseModel>>(
                    stream: accessService.getUserPurchasesStream(userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF280A54),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Color(0xFF280A54)),
                          ),
                        );
                      }

                      final purchases = snapshot.data ?? [];
                      if (purchases.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 60,
                                  color: Color(0xFF38106A),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'You have no purchases yet.',
                                style: TextStyle(
                                  color: Color(0xFF280A54),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 8.0,
                        ),
                        itemCount: purchases.length,
                        itemBuilder: (context, index) {
                          final p = purchases[index];
                          final isExpired =
                              p.expiresAt != null &&
                              p.expiresAt!.isBefore(DateTime.now());

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.shopping_bag,
                                  color: Color(0xFF8841FF),
                                  size: 28,
                                ),
                              ),
                              title: Text(
                                'Item ID: ${p.itemId}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF280A54),
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Type: ${p.itemType.toUpperCase()}\n'
                                  'Purchased: ${p.purchasedAt.toString().split('.')[0]}\n'
                                  'Status: ${isExpired ? "EXPIRED" : p.status.toUpperCase()}',
                                  style: TextStyle(
                                    color: const Color(
                                      0xFF38106A,
                                    ).withValues(alpha: 0.8),
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              isThreeLine: true,
                              trailing: isExpired
                                  ? const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Color(0xFFD32F2F),
                                    )
                                  : const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF388E3C),
                                    ),
                            ),
                          );
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
}
