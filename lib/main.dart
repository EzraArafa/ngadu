import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/env_config.dart';
import 'providers/auth_provider.dart';
import 'providers/complaint_provider.dart';
import 'providers/ui_state_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/complaint_form.dart';
import 'screens/my_complaints_screen.dart';
import 'screens/complaint_detail.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  await initializeDateFormatting('id_ID', null);

  if (EnvConfig.isConfigured) {
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl!,
      publishableKey: EnvConfig.supabaseAnonKey!,
    );
  }

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
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (c) => const SplashScreen(),
          '/auth': (c) => const AuthScreen(),
          '/home': (c) => const HomeScreen(),
          '/form': (c) => const ComplaintFormScreen(),
          '/my': (c) => const MyComplaintsScreen(),
          '/detail': (c) => const ComplaintDetailScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}