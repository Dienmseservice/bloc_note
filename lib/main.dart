import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'views/welcome_view.dart';

void main() {
  // Garantit la bonne initialisation des liaisons Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Si l'application s'exécute sur le Web, on redirige SQLite vers l'adaptateur virtuel Web
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  runApp(const EcoSaveNotesApp());
}

class EcoSaveNotesApp extends StatelessWidget {
  const EcoSaveNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoSave Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF059669),
        scaffoldBackgroundColor: Colors.white,
      ),
      // La page d'accueil de l'application (Splash/Welcome)
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeView(),
      },
    );
  }
}