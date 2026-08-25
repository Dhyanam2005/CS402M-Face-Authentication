import 'package:flutter/material.dart';
import 'package:face_auth_ransomware/screens/auth_screen.dart';
import 'package:face_auth_ransomware/screens/home_screen.dart';
import 'package:face_auth_ransomware/screens/ransom_note_screen.dart';

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