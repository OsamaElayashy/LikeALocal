import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
// import 'screens/place/place_detail_screen.dart';
// import 'screens/place/add_place_screen.dart';
// import 'screens/chat/localbot_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'LikeALocal',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Helvetica',
          scaffoldBackgroundColor: Colors.white,
          primaryColor: const Color(0xFF2563EB),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            background: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF1A1A2E),
            elevation: 0,
            centerTitle: false,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFF2563EB), width: 1.5),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            labelStyle: const TextStyle(color: Color(0xFF6B7280)),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (ctx) => const SplashScreen(),
          '/login': (ctx) => const LoginScreen(),
          '/register': (ctx) => const RegisterScreen(),
          '/home': (ctx) => const HomeScreen(),
          // '/add-place': (ctx) => const AddPlaceScreen(),
          // '/localbot': (ctx) => const LocalBotScreen(),
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
    );
  }
}