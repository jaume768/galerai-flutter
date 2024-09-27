import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:galerai/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización manual de Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAE5ekWOHmjc58B7ATPm0CPf3s4LZ7TRD8",
      appId: "1:956911173915:android:e3c7a20d9d3ae2ccc753be",
      messagingSenderId: "956911173915",
      projectId: "galerai-6cbc6",
      storageBucket: "galerai-6cbc6.appspot.com",
    ),
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GalerAI',
      debugShowCheckedModeBanner: false, // Elimina el banner de "Debug"
      theme: ThemeData.dark().copyWith(
        colorScheme: ThemeData.dark().colorScheme.copyWith(
          secondary: Colors.blueAccent,
        ),
      ),
      home: HomePage(),
    );
  }
}
