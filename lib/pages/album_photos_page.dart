// album_photos_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'photo_grid_item.dart';

class AlbumPhotosPage extends StatelessWidget {
  final String albumId;
  final String albumName;

  AlbumPhotosPage({required this.albumId, required this.albumName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Álbum: $albumName'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('photos')
            .where('albumId', isEqualTo: albumId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();

          var photos = snapshot.data!.docs;

          if (photos.isEmpty) {
            return Center(child: Text('No hay fotos en este álbum.'));
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
