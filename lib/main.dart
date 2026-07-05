import 'package:flutter/material.dart';
import 'views/welcome_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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