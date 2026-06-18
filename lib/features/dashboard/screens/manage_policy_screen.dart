import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:lms/core/providers/theme_provider.dart';

class ManagePolicyScreen extends StatefulWidget {
  const ManagePolicyScreen({super.key});

  @override
  State<ManagePolicyScreen> createState() => _ManagePolicyScreenState();
}

class _ManagePolicyScreenState extends State<ManagePolicyScreen> {
  final TextEditingController _termsController = TextEditingController();
  final TextEditingController _privacyController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPolicy();
  }

  Future<void> _loadPolicy() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('legal')
          .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          _termsController.text = data['terms'] ?? '';
          _privacyController.text = data['privacy'] ?? '';
        }
      }
    } catch (e) {
      debugPrint('Error loading policy: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePolicy() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('legal')
          .set({
            'terms': _termsController.text.trim(),
            'privacy': _privacyController.text.trim(),
            'updated_at': FieldValue.serverTimestamp(),
          });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Legal policies updated successfully.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _termsController.dispose();
    _privacyController.dispose();
    super.dispose();
  }

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
    final cText = isDark ? Colors.white : const Color(0xFF1A0845);
    final cAccent = const Color(0xFF7C3AED);

    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        title: Text('Manage Legal Policies', style: TextStyle(color: cText)),
        backgroundColor: cBg,
        iconTheme: IconThemeData(color: cText),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: cAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Terms & Conditions',
                    style: TextStyle(
                      color: cText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _termsController,
                    'Enter Terms and Conditions...',
                    cCardBg,
                    cBorder,
                    cText,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Privacy Policy',
                    style: TextStyle(
                      color: cText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _privacyController,
                    'Enter Privacy Policy...',
                    cCardBg,
                    cBorder,
                    cText,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _savePolicy,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Save Policies',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    Color bg,
    Color border,
    Color text,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        style: TextStyle(color: text),
        maxLines: 8,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: text.withValues(alpha: 0.5)),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
