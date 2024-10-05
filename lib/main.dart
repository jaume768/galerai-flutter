// main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:galerai/pages/home_page.dart';
import 'package:galerai/pages/login_page.dart';
import 'package:galerai/pages/register_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAE5ekWOHmjc58B7ATPm0CPf3s4LZ7TRD8",
      appId: "1:956911173915:android:e3c7a20d9d3ae2ccc753be",
      messagingSenderId: "956911173915",
      projectId: "galerai-6cbc6",
      storageBucket: "galerai-6cbc6.appspot.com",
    ),
  );

  // Inicialización de Hive
  await Hive.initFlutter();

  // Abrir las cajas de Hive
  await Hive.openBox('photosBox');
  print('photosBox abierta');

  await Hive.openBox('albumsBox');
  print('albumsBox abierta');

  // Habilitar la persistencia offline de Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final FlutterSecureStorage storage = FlutterSecureStorage();

  Future<bool> _checkLoggedIn() async {
    String? userId = await storage.read(key: 'userId');
    return userId != null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GalerAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ThemeData.dark().colorScheme.copyWith(
              secondary: Colors.blueAccent,
            ),
      ),
      routes: {
        '/home': (context) => HomePage(),
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
      },
      home: FutureBuilder<bool>(
        future: _checkLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else {
            if (snapshot.data == true) {
              return HomePage();
            } else {
              return LoginPage();
            }
          }
        },
      ),
    );
  }
}
