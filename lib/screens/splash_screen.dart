import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// S-01 Splash Screen: cek sesi login secara otomatis.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Variabel authProvider sudah di-set di main.dart sebelum runApp,
    // jadi cukup baca status saat ini.
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final auth = context.read<AuthController>();
    Navigator.pushReplacementNamed(
      context,
      auth.isAuthenticated ? '/home' : '/auth',
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.report_problem_outlined, size: 64, color: Color(0xFF1565C0)),
            SizedBox(height: 16),
            Text(
              'NGADU',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 8),
            Text('Aduan Fasilitas Kampus'),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
