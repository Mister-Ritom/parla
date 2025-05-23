import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parla/auth/auth_provider.dart';
import 'package:parla/auth/auth_gate.dart';
import 'package:parla/firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Stop the firebase persistence for debug mode
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: !kDebugMode,
  );
  runApp(
    ChangeNotifierProvider(create: (_) => AuthProvider(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Parla',
      theme: ThemeData(
        focusColor: Colors.lightBlue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          secondary: Colors.blueAccent,
        ),
        useMaterial3: true,
        textTheme: TextTheme(
          headlineMedium: GoogleFonts.lato().copyWith(
            fontFamilyFallback: ['Roboto'],
          ),
          bodyLarge: GoogleFonts.roboto().copyWith(
            fontFamilyFallback: ['Roboto'],
          ),
          bodyMedium: GoogleFonts.roboto().copyWith(
            fontFamilyFallback: ['Roboto'],
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        focusColor: Colors.lightBlue,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: Colors.purple,
          secondary: Colors.blueAccent,
        ),
        useMaterial3: true,
        textTheme: TextTheme(
          headlineMedium: GoogleFonts.lato().copyWith(
            fontFamilyFallback: ['Roboto'],
          ),
          bodyLarge: GoogleFonts.roboto().copyWith(
            fontFamilyFallback: ['Roboto'],
          ),
          bodyMedium: GoogleFonts.roboto().copyWith(
            fontFamilyFallback: ['Roboto'],
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }
}
