import 'package:flutter/material.dart';
import 'package:lms/core/constants/app_colors.dart';

/// A full-screen loading overlay with an animated spinner and optional message.
class LoadingOverlay extends StatelessWidget {
  final String? message;

  const LoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated logo / spinner
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accent,
                    strokeWidth: 3,
                  ),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 24),
                Text(
                  message!,
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
