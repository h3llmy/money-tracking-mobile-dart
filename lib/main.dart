import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'theme/app_theme.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/login_screen.dart';
import 'services/notification_handler.dart';
import 'services/api_service.dart';
import 'providers/data_providers.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Load saved API base URL before building the widget tree
  final savedBaseUrl = await ApiService.getSavedBaseUrl();

  // Launch the UI immediately — nothing blocks the first frame
  runApp(
    ProviderScope(
      overrides: [
        baseUrlProvider.overrideWith(() => BaseUrlNotifier(savedBaseUrl)),
      ],
      child: const MyApp(),
    ),
  );

  // Initialize the notification listener after UI is stable
  _initServices();

  // Remove splash screen once everything is ready
  FlutterNativeSplash.remove();
}

Future<void> _initServices() async {
  // Give the widget tree time to fully mount before touching native plugins
  await Future.delayed(const Duration(milliseconds: 500));

  try {
    await NotificationsListener.initialize(
      callbackHandle: onNotificationBackgroundCallback,
    );
  } catch (e) {
    debugPrint('Error initializing notification listener: $e');
  }

  try {
    final bool hasPermission =
        await NotificationsListener.hasPermission ?? false;
    if (hasPermission) {
      final isRunning = await NotificationsListener.isRunning ?? false;
      if (!isRunning) {
        await NotificationsListener.startService();
      }
      debugPrint('Notification listener is active.');
    } else {
      debugPrint('Notification permission not granted.');
    }
  } catch (e) {
    debugPrint('Error starting notification listener service: $e');
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    Widget homeScreen;
    if (authState.isLoading) {
      homeScreen = const Scaffold(
        backgroundColor: Color(0xFF0B0F19),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      );
    } else if (authState.isAuthenticated) {
      homeScreen = const MainNavigationScreen();
    } else {
      homeScreen = const LoginScreen();
    }

    return MaterialApp(
      title: 'Hexagonal Finance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: homeScreen,
    );
  }
}
