// favorite_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'photo_grid_item.dart';
import 'package:hive/hive.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage storage = FlutterSecureStorage();
  final Box _photosBox = Hive.box('photosBox');
  final _searchSubject = BehaviorSubject<String>();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Stream<QuerySnapshot<Object?>>? _favoritesStream;
  String? userId;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _searchSubject.debounceTime(Duration(milliseconds: 500)).listen((value) {
      setState(() {
        _searchQuery = value.length >= 3 ? value : '';
      });
    });
  }

  Future<void> _initializeUser() async {
    userId = await storage.read(key: 'userId');
    setState(() {
      _favoritesStream = _firestore
          .collection('photos')
          .where('ownerId', isEqualTo: userId)
          .where('isFavorite', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .snapshots();

      // Escuchar los cambios en favoritos y actualizar Hive
      _favoritesStream!.listen((snapshot) async {
        List<QueryDocumentSnapshot<Object?>> favorites = snapshot.docs;

        // Obtener IDs actuales de favoritos desde Firestore
        List<String> currentFavoriteIds =
            favorites.map((doc) => doc.id).toList();

        // Obtener IDs actuales almacenados en Hive
        List<String> hiveFavoriteIds = _photosBox.keys.cast<String>().toList();

        // Determinar IDs a eliminar
        List<String> idsToRemove = hiveFavoriteIds
            .where((id) => !currentFavoriteIds.contains(id))
            .toList();

        // Eliminar de Hive
        for (var id in idsToRemove) {
          await _photosBox.delete(id);
        }

        // Agregar o actualizar en Hive
        for (var doc in favorites) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          // Convertir Timestamp a DateTime
          if (data['timestamp'] is Timestamp) {
            data['timestamp'] = (data['timestamp'] as Timestamp).toDate();
          }

          _photosBox.put(doc.id, data);
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchSubject.close();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterFavorites(
      List<Map<String, dynamic>> favorites) {
    if (_searchQuery.isEmpty) {
      return favorites;
    } else {
      return favorites.where((photo) {
        String description = photo['description'] ?? '';
        List<dynamic> tags = photo['tags'] ?? [];
        String tagsString = tags.join(' ');
        String combined = description + ' ' + tagsString;
        return combined.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Obtener las fotos favoritas desde Hive
    List<Map<String, dynamic>> cachedFavorites = _photosBox.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((photo) =>
            photo['isFavorite'] == true && photo['ownerId'] == userId)
        .toList();

    List<Map<String, dynamic>> filteredFavorites =
        _filterFavorites(cachedFavorites);

    return Scaffold(
      appBar: _buildAppBar(),
      body: filteredFavorites.isEmpty
          ? Center(child: Text('No hay fotos favoritas.'))
          : GridView.builder(
              padding: EdgeInsets.all(10.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
              ),
              itemCount: filteredFavorites.length,
              itemBuilder: (context, index) {
                var photo = filteredFavorites[index];
                return PhotoGridItem(
                  photoData: photo,
                  onImageError: (id) {},
                );
              },
            ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text('Favoritos'),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Buscar por descripción o tags',
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey[800],
              contentPadding: EdgeInsets.all(10.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              _searchSubject.add(value);
            },
          ),
        ),
      ),
    );
  }
}
