import 'package:capydoc/screens/auth.dart';
import 'package:capydoc/screens/docs.dart';
import 'package:capydoc/screens/profile.dart';
import 'package:capydoc/screens/splash.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Capydoc',
      theme: ThemeData().copyWith(
        colorScheme:
            ColorScheme.fromSeed(seedColor: Color.fromARGB(207, 182, 224, 186)),
      ),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          if (snapshot.hasData) {
            return DocsScreen();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}
