import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/complaint_provider.dart';
import 'providers/ui_state_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/complaint_form.dart';
import 'screens/my_complaints_screen.dart';
import 'screens/complaint_detail.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi Supabase (URL & key lewat dart-define). Jika belum, app akan
  // tetap jalan namun fungsionalitas backend tidak aktif.
  // SupabaseService.isConfigured dapat dipanggil di provider bila perlu.
  runApp(const NgaduApp());
}

class NgaduApp extends StatelessWidget {
  const NgaduApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ComplaintProvider()),
        ChangeNotifierProvider(create: (_) => UiStateProvider()),
      ],
      child: MaterialApp(
        title: 'Ngadu',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (c) => const SplashScreen(),
          '/auth': (c) => const AuthScreen(),
          '/home': (c) => const HomeScreen(),
          '/form': (c) => const ComplaintFormScreen(),
          '/my': (c) => const MyComplaintsScreen(),
          '/detail': (c) => const ComplaintDetailScreen(),
          // Admin status modal dibuka via showDialog, tidak ada route terpisah.
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
