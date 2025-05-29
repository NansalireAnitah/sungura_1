import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:front_end/screens/admin_dashboard_screen.dart';
import 'package:front_end/screens/menu_screen.dart';
import 'package:front_end/providers/order_provider.dart';
import 'package:front_end/providers/product_provider.dart';
import 'package:front_end/providers/notification_provider.dart';
import 'package:front_end/providers/cart_provider.dart';
import 'package:front_end/providers/auth_provider.dart';
import 'package:front_end/providers/admin_user_provider.dart'; // Add this import
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
    // Initialize Firebase only if not already initialized
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase initialized successfully");

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => MyAuthProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => ProductProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ChangeNotifierProvider(create: (_) => OrderProvider()),
          ChangeNotifierProvider(
              create: (_) => AdminUserProvider()), // Add this line
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    // Check if the error is specifically about duplicate app initialization
    if (e.toString().contains('duplicate-app') ||
        e.toString().contains('already exists')) {
      debugPrint("Firebase already initialized, continuing with app startup");
      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MyAuthProvider()),
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => ProductProvider()),
            ChangeNotifierProvider(create: (_) => NotificationProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
            ChangeNotifierProvider(
                create: (_) => AdminUserProvider()), // Add this line here too
          ],
          child: const MyApp(),
        ),
      );
    } else {
      debugPrint("🔥 Firebase Initialization Error: $e");
      debugPrintStack(stackTrace: stackTrace);
      runApp(const ErrorApp());
    }
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
          textDirection: TextDirection.ltr,
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
        '/authWrapper': (context) => const AuthWrapper(),
      },
    );
  }
}

class SplashScreenWrapper extends StatelessWidget {
  const SplashScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return SplashScreen(
        onAddToCart: (product) {},
        onFinish: () {
          Navigator.of(context).pushReplacementNamed('/authWrapper');
        });
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MyAuthProvider>(context);

    // Wait for MyAuthProvider to initialize
    if (!authProvider.isInitialized) {
      debugPrint('AuthWrapper: Waiting for MyAuthProvider initialization');
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Check if user is authenticated
    if (authProvider.user == null) {
      debugPrint(
          'AuthWrapper: No user authenticated, redirecting to LoginScreen');
      return const LoginScreen();
    }

    // Route based on role
    final role = authProvider.role ?? 'user';
    debugPrint('AuthWrapper: User authenticated, role: $role');

    return role == 'admin' ? const AdminDashboard() : const HomeScreen();
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
                  // Note: Calling main() recursively isn't ideal.
                  // Consider using a proper restart mechanism instead.
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
