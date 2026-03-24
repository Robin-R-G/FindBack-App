import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/about_us_screen.dart';
import 'screens/register_screen.dart';
import 'screens/qr_display_screen.dart';
import 'screens/qr_scan_screen.dart';
import 'screens/report_screen.dart';

import 'screens/scan_result_screen.dart';

import 'config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.init();
  runApp(const FindBackApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/about',
      builder: (context, state) => const AboutUsScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/qr_display',
      builder: (context, state) => const QRDisplayScreen(),
    ),
    GoRoute(
      path: '/scan',
      builder: (context, state) => const QRScanScreen(),
    ),
    GoRoute(
      path: '/scan_result',
      builder: (context, state) {
        final Map<String, dynamic> data = state.extra as Map<String, dynamic>;
        return ScanResultScreen(studentData: data);
      },
    ),
    GoRoute(
      path: '/report',
      builder: (context, state) {
        final String? id = state.extra as String?;
        return ReportScreen(studentId: id);
      },
    ),
  ],
);

class FindBackApp extends StatelessWidget {
  const FindBackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FindBack App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90E2),
          primary: const Color(0xFF4A90E2),
          secondary: const Color(0xFF7B61FF),
          tertiary: Colors.green, // Accent Green
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      routerConfig: _router,
    );
  }
}
