import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/ransom_note_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Authentication System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/ransom': (context) => const RansomNoteScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}