import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:front_end/screens/admin_dashboard_screen.dart';
import 'package:front_end/screens/menu_screen.dart';
import 'package:front_end/providers/admin_user_provider.dart';
import 'package:front_end/providers/order_provider.dart';
import 'package:front_end/providers/product_provider.dart';
import 'package:front_end/providers/notification_provider.dart';
import 'package:front_end/providers/cart_provider.dart';
import 'package:front_end/providers/auth_provider.dart';
import 'package:front_end/screens/splash_screen.dart';
import 'package:front_end/screens/signup.dart';
import 'package:front_end/screens/home_screen.dart';
import 'package:front_end/screens/login_screen.dart';
import 'package:front_end/screens/profile_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    debugPrint("🚨 Flutter Error: ${details.exceptionAsString()}");
  };

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase initialized successfully");
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => MyAuthProvider()),
          ChangeNotifierProvider(create: (_) => AdminUserProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => ProductProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ChangeNotifierProvider(create: (_) => OrderProvider()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint("🔥 Firebase Error: $e");
    debugPrintStack(stackTrace: stackTrace);
    runApp(const ErrorApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sungura Restaurant',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.light(useMaterial3: true),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr, // Enforce LTR globally
          child: child!,
        );
      },
      home: const SplashScreenWrapper(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/home': (context) => const HomeScreen(),
        '/menu': (context) => const MenuScreen(),
        '/signup': (context) => const SignUpScreen(isEditing: false),
        '/login': (context) => const LoginScreen(),
        '/admin': (context) => const AdminDashboard(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

class SplashScreenWrapper extends StatelessWidget {
  const SplashScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return SplashScreen(onAddToCart: (product) {}, onFinish: () {});
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error.toString()}'),
            ),
          );
        }

        if (snapshot.hasData) {
          return FutureBuilder<String?>(
            future: Provider.of<MyAuthProvider>(context, listen: false)
                .getUserRole(snapshot.data!.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (roleSnapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Text('Error: ${roleSnapshot.error.toString()}'),
                  ),
                );
              }

              final role = roleSnapshot.data;
              return role == 'admin' ? const AdminDashboard() : const HomeScreen();
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 72, color: Colors.red[700]),
              const SizedBox(height: 24),
              Text(
                'Initialization Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'The application failed to initialize properly. '
                'Please check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  main();
                },
                child: const Text('RESTART APP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}