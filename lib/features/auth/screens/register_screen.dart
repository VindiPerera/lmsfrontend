import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lms/core/constants/app_colors.dart';
import 'package:lms/core/constants/app_text_styles.dart';
import 'package:lms/features/auth/providers/auth_provider.dart';
import 'package:lms/features/auth/screens/login_screen.dart';
import 'package:lms/core/providers/theme_provider.dart';

// ── Theme-aware color helper ─────────────────────────────────────────────────
class _AuthColors {
  final bool isDark;
  _AuthColors(this.isDark);

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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'Student'; // default role
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final fullName =
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';

    final success = await authProvider.register(
      name: fullName,
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole.toLowerCase(),
    );

    if (!mounted) return;

    if (success) {
      navigator.popUntil((route) => route.isFirst);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text('Account created successfully! Welcome!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      _showError(authProvider.errorMessage ?? 'Registration failed');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    final authProvider = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final result = await authProvider.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    switch (result) {
      case GoogleSignInResult.existingUser:
        navigator.popUntil((route) => route.isFirst);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('Logged in successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        break;
      case GoogleSignInResult.newUser:
        final ok = await authProvider.completeGoogleRegistration(
          _selectedRole.toLowerCase(),
        );
        if (!ok && mounted) {
          _showError(
            authProvider.errorMessage ?? 'Failed to complete registration.',
          );
        } else if (ok && mounted) {
          navigator.popUntil((route) => route.isFirst);
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: const Text('Account created successfully! Welcome!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        break;
      case GoogleSignInResult.cancelled:
        break;
      case GoogleSignInResult.error:
        _showError(authProvider.errorMessage ?? 'Google Sign-In failed');
        break;
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final c = _AuthColors(isDark);

    return Scaffold(
      backgroundColor: c.bgColor1,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Background Gradient ──────────────────────────────────────
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

          // ── Decorative Mesh Orbs ─────────────────────────────────────
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

          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: c.cardBg,
                shape: BoxShape.circle,
                border: Border.all(color: c.cardBorder),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
                onPressed: () =>
                    Navigator.canPop(context) ? Navigator.pop(context) : null,
                tooltip: 'Go Back',
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 420),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: c.cardBg,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: c.cardBorder, width: 1.5),
                        boxShadow: c.cardShadow,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Icon(
                              Icons.layers_rounded,
                              color: c.accentBright,
                              size: 40,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'FaceTalk',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: c.textPrimary,
                                fontSize: 13,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'Create Account',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: c.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 32),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildGlassTextField(
                                    controller: _firstNameController,
                                    labelText: 'First Name',
                                    c: c,
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildGlassTextField(
                                    controller: _lastNameController,
                                    labelText: 'Last Name',
                                    c: c,
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            _buildGlassTextField(
                              controller: _emailController,
                              labelText: 'Email Address',
                              c: c,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 20),

                            _buildGlassTextField(
                              controller: _phoneController,
                              labelText: 'Phone Number',
                              c: c,
                              keyboardType: TextInputType.phone,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 20),

                            Text(
                              'I am a',
                              style: TextStyle(
                                color: c.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: c.isDark
                                    ? Colors.black.withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: c.cardBorder,
                                  width: 1,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedRole,
                                  dropdownColor: c.isDark
                                      ? const Color(0xFF150C2E)
                                      : Colors.white,
                                  icon: Icon(
                                    Icons.arrow_drop_down_rounded,
                                    color: c.textSecondary,
                                  ),
                                  isExpanded: true,
                                  items: ['Student', 'Teacher']
                                      .map(
                                        (role) => DropdownMenuItem(
                                          value: role,
                                          child: Text(
                                            role,
                                            style: TextStyle(
                                              color: c.textPrimary,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null)
                                      setState(() => _selectedRole = val);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            _buildGlassTextField(
                              controller: _passwordController,
                              labelText: 'Password',
                              c: c,
                              obscureText: true,
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 20),

                            _buildGlassTextField(
                              controller: _confirmPasswordController,
                              labelText: 'Confirm Password',
                              c: c,
                              obscureText: true,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if (v != _passwordController.text)
                                  return 'Passwords do not match';
                                return null;
                              },
                            ),

                            const SizedBox(height: 32),

                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: c.accentPrimary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: authProvider.isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 16),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: _isGoogleLoading
                                    ? null
                                    : _handleGoogleSignIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: c.isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.white.withValues(alpha: 0.7),
                                  foregroundColor: c.textPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: c.cardBorder,
                                      width: 1.5,
                                    ),
                                  ),
                                  elevation: 0,
                                ),
                                icon: _isGoogleLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: c.textPrimary,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        Icons.g_mobiledata_rounded,
                                        size: 28,
                                        color: c.textPrimary,
                                      ),
                                label: const Text(
                                  'Continue with Google',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: TextStyle(
                                    color: c.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Text(
                                    'Login',
                                    style: TextStyle(
                                      color: c.accentBright,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton.icon(
                                onPressed: () {
                                  Navigator.popUntil(
                                    context,
                                    (route) => route.isFirst,
                                  );
                                },
                                icon: Icon(
                                  Icons.home_rounded,
                                  color: c.textSecondary,
                                ),
                                label: Text(
                                  'Back to Home',
                                  style: TextStyle(
                                    color: c.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String labelText,
    required _AuthColors c,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: TextStyle(color: c.textPrimary, fontSize: 15),
          validator: validator,
          cursorColor: c.accentBright,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            filled: true,
            fillColor: c.isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.5),
            suffixIcon: suffixIcon,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: c.cardBorder, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: c.accentBright, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
