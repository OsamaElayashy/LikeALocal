import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_place_screen.dart';
import 'screens/bookmarks_screen.dart';
import 'package:likealocal/services/notification_service.dart';
import 'package:likealocal/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // Initialize notifications
  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermission();

  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: Consumer<AppProvider>(
        builder: (context, app, _) => MaterialApp(
          title: 'LikeALocal',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: app.themeMode,
          initialRoute: '/',
          routes: {
            '/': (ctx) => const SplashScreen(),
            '/login': (ctx) => const LoginScreen(),
            '/register': (ctx) => const RegisterScreen(),
            '/home': (ctx) => const HomeScreen(),
            '/add-place': (ctx) => const AddPlaceScreen(),
            '/bookmarks': (ctx) => const BookmarksScreen(),
          },
          onGenerateRoute: (settings) {
            // Place detail needs an argument (the Place object)
            /*
            if (settings.name == '/place-detail') {
              return MaterialPageRoute(
                builder: (ctx) => const PlaceDetailScreen(),
                settings: settings,
              );
            }
            */
            return null;
          },
        ),
      ),
    );
  }
}
