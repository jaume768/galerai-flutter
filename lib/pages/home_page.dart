// home_page.dart

import 'package:flutter/material.dart';
import 'package:galerai/pages/all_photos_page.dart';
import 'package:galerai/pages/albums_page.dart';
import 'package:galerai/pages/favorite_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final FlutterSecureStorage storage = FlutterSecureStorage();

  final List<Widget> _children = [
    AllPhotosPage(),
    AlbumsPage(),
    FavoritesPage(),
  ];

  void _logout() async {
    await storage.delete(key: 'userId');
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GalerAI'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.photo), label: 'Fotos'),
          BottomNavigationBarItem(icon: Icon(Icons.album), label: 'Álbumes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: 'Favoritos'),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
