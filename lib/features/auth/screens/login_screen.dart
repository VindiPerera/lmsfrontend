import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lms/core/constants/app_colors.dart';
import 'package:lms/core/constants/app_text_styles.dart';
import 'package:lms/features/auth/providers/auth_provider.dart';
import 'package:lms/features/auth/screens/register_screen.dart';
import 'package:lms/core/providers/theme_provider.dart';

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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!success && mounted) {
      _showError(authProvider.errorMessage ?? 'Login failed');
    } else if (success) {
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
        _showRoleSelectionDialog();
        break;
      case GoogleSignInResult.cancelled:
        break;
      case GoogleSignInResult.error:
        _showError(authProvider.errorMessage ?? 'Google Sign-In failed');
        break;
    }
  }

  void _showRoleSelectionDialog() {
    String selectedRole = 'student';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = context.watch<ThemeProvider>().isDarkMode;
            final c = _AuthColors(isDark);

            return AlertDialog(
              backgroundColor: c.bgColor1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: c.cardBorder),
              ),
              title: Text(
                'Select Your Role',
                style: AppTextStyles.heading3.copyWith(color: c.textPrimary),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Welcome! Please choose your role to complete registration.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _RoleTile(
                    icon: Icons.school_rounded,
                    title: 'Student',
                    subtitle: 'Enroll in courses & learn',
                    selected: selectedRole == 'student',
                    c: c,
                    onTap: () => setDialogState(() => selectedRole = 'student'),
                  ),
                  const SizedBox(height: 10),
                  _RoleTile(
                    icon: Icons.cast_for_education_rounded,
                    title: 'Teacher',
                    subtitle: 'Create & manage courses',
                    selected: selectedRole == 'teacher',
                    c: c,
                    onTap: () => setDialogState(() => selectedRole = 'teacher'),
                  ),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.accentPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final authProvider = context.read<AuthProvider>();
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);

                      Navigator.pop(ctx);
                      final ok = await authProvider.completeGoogleRegistration(
                        selectedRole,
                      );

                      if (!ok && mounted) {
                        _showError(
                          authProvider.errorMessage ??
                              'Failed to complete registration.',
                        );
                      } else if (ok) {
                        navigator.popUntil((route) => route.isFirst);
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Account created successfully! Welcome!',
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      }
                    },
                    child: const Text('Continue'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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
                              'Welcome Back',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: c.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 32),

                            _buildGlassTextField(
                              controller: _emailController,
                              labelText: 'Email address',
                              c: c,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Please enter your email'
                                  : null,
                            ),
                            const SizedBox(height: 20),

                            _buildGlassTextField(
                              controller: _passwordController,
                              labelText: 'Password',
                              c: c,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: c.textSecondary,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Please enter your password'
                                  : null,
                            ),

                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Forget Password ?',
                                  style: TextStyle(
                                    color: c.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : _handleLogin,
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
                                        'Login',
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
                                  'Are You New Member ? ',
                                  style: TextStyle(
                                    color: c.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Sign UP',
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

class _RoleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final _AuthColors c;
  final VoidCallback onTap;

  const _RoleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.c,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? c.accentPrimary.withValues(alpha: 0.15)
              : c.isDark
              ? Colors.black.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? c.accentPrimary : c.cardBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? c.accentBright : c.textSecondary,
              size: 28,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.label.copyWith(
                      color: selected ? c.accentBright : c.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: c.accentBright, size: 22),
          ],
        ),
      ),
    );
  }
}
