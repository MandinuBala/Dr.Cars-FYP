import 'package:dr_cars_fyp/auth/auth_service.dart';
import 'package:dr_cars_fyp/auth/welcome.dart';
import 'package:dr_cars_fyp/service/service_menu.dart';
import 'package:flutter/material.dart';
import 'package:dr_cars_fyp/user/main_dashboard.dart';
import 'package:dr_cars_fyp/admin/dashboard/admin_dashboard_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:dr_cars_fyp/providers/locale_provider.dart';
import 'package:dr_cars_fyp/theme/app_theme.dart';
import 'package:dr_cars_fyp/service/document_notification_service.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DocumentNotificationService.init();
  OneSignal.initialize("fd5e46c1-2563-4dd9-8b53-931517023f89");

  final prefs = await SharedPreferences.getInstance();
  bool isDarkMode = prefs.getBool('darkMode') ?? false;
  themeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;

  await initLocale();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode mode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(Brightness.light), // ← luxury light
          darkTheme: buildAppTheme(Brightness.dark), // ← luxury dark
          themeMode: mode,
          home: const AuthCheck(),
        );
      },
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});
  @override
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  Future<void> _checkUser() async {
    final user = await _authService.getCurrentUser();
    final type =
        user?['userType']?.toString() ??
        user?['User Type']?.toString() ??
        'User';
    final screen = _screenForUserType(type);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Widget _screenForUserType(String type) {
    switch (type) {
      case 'Vehicle Owner':
        return const DashboardScreen();
      case 'Service Center':
        return const HomeScreen();
      case 'App Admin':
        return const ServiceCenterApprovalPage();
      default:
        return const Welcome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.richBlack,
      body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
    );
  }
}
