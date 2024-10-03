// favorites_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'photo_grid_item.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _photosStream = FirebaseFirestore.instance
        .collection('photos')
        .where('isFavorite', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text('Favoritos'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _photosStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();

          var photos = snapshot.data!.docs;

          if (photos.isEmpty) {
            return Center(child: Text('No hay fotos favoritas.'));
          }

          return GridView.builder(
            padding: EdgeInsets.all(10.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              var photo = photos[index];
              return PhotoGridItem(
                photo: photo,
                onImageError: (id) {},
              );
            },
          );
        },
      ),
    );
  }
}
