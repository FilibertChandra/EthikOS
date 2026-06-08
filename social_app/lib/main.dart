import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/post_provider.dart';
import 'services/api_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/feed_screen.dart';

// Global navigator key so we can navigate (e.g. force logout) from outside the
// widget tree, such as when an API call returns 401.
final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
      ],
      child: MaterialApp(
        title: 'EthikOS',
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        builder: (context, child) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child!,
            ),
          );
        },
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _registerUnauthorizedHandler();
    _checkLoginStatus();
  }

  // When any API call returns 401 (expired/invalid token), log out and return
  // to the login screen.
  void _registerUnauthorizedHandler() {
    ApiService.onUnauthorized = () async {
      if (_loggingOut) return; // avoid duplicate redirects
      _loggingOut = true;

      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        await Provider.of<AuthProvider>(ctx, listen: false).logout();
      }
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      _loggingOut = false;
    };
  }

  Future<void> _checkLoginStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLoggedIn = await authProvider.checkLoginStatus();
    setState(() {
      _isLoggedIn = isLoggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _isLoggedIn ? const FeedScreen() : const LoginScreen();
  }
}
