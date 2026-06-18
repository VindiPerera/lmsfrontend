import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

import 'package:lms/core/constants/app_theme.dart';
import 'package:lms/core/providers/theme_provider.dart';
import 'package:lms/core/providers/cart_provider.dart';
import 'package:lms/features/auth/providers/auth_provider.dart';
import 'package:lms/shared/widgets/main_shell.dart';
import 'package:lms/features/splash/screens/splash_screen.dart';
import 'package:lms/features/onboarding/screens/onboarding_screen.dart';

import 'package:lms/core/providers/navigation_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();
  final bool seenOnboarding = prefs.getBool('seen_onboarding') ?? false;

  runApp(MyApp(seenOnboarding: seenOnboarding));
}

class MyApp extends StatelessWidget {
  final bool seenOnboarding;
  const MyApp({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, themeProvider, authProvider, child) {
          return MaterialApp(
            title: 'FaceTalk',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: authProvider.isLoading
                ? const CustomSplashScreen()
                : (seenOnboarding
                      ? const MainShell()
                      : const OnboardingScreen()),
          );
        },
      ),
    );
  }
}
