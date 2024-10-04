// albums_page.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'album_photos_page.dart';
import 'package:hive/hive.dart';

class AlbumsPage extends StatefulWidget {
  const AlbumsPage({Key? key}) : super(key: key);

  @override
  _AlbumsPageState createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _albumNameController = TextEditingController();
  final Box _albumsBox = Hive.box('albumsBox'); // Asegúrate de que el nombre coincide

  void _createAlbum() async {
    String albumName = _albumNameController.text.trim();
    if (albumName.isEmpty) return;

    DocumentReference docRef = await _firestore.collection('albums').add({
      'name': albumName,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _albumsBox.put(docRef.id, {
      'name': albumName,
      'createdAt': DateTime.now().toIso8601String(),
    });

    _albumNameController.clear();
    Navigator.of(context).pop();
  }

  void _showCreateAlbumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Crear Álbum'),
        content: TextField(
          controller: _albumNameController,
          decoration: InputDecoration(hintText: 'Nombre del álbum'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _albumNameController.clear();
              Navigator.of(context).pop();
            },
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: _createAlbum,
            child: Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _deleteAlbum(QueryDocumentSnapshot album) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Álbum'),
        content: Text(
            '¿Estás seguro de que deseas eliminar el álbum "${album['name']}"? Todas las fotos asociadas se desasignarán de este álbum.'),
        actions: [
          TextButton(
            child: Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text('Eliminar'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm) {
      // Desasignar albumId de las fotos que pertenecen al álbum
      var photosSnapshot = await _firestore
          .collection('photos')
          .where('albumId', isEqualTo: album.id)
          .get();

      for (var photo in photosSnapshot.docs) {
        await photo.reference.update({'albumId': null});
      }

      // Eliminar el álbum
      await _firestore.collection('albums').doc(album.id).delete();

      // Eliminar del caché local
      _albumsBox.delete(album.id);
    }
  }

  void _showEditAlbumDialog(QueryDocumentSnapshot album) {
    _albumNameController.text = album['name'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Álbum'),
        content: TextField(
          controller: _albumNameController,
          decoration: InputDecoration(hintText: 'Nombre del álbum'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _albumNameController.clear();
              Navigator.of(context).pop();
            },
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              String newName = _albumNameController.text.trim();
              if (newName.isNotEmpty) {
                await album.reference.update({'name': newName});
                _albumsBox.put(album.id, {
                  'name': newName,
                  'createdAt': DateTime.now().toIso8601String(),
                });
              }
              _albumNameController.clear();
              Navigator.of(context).pop();
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Álbumes'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showCreateAlbumDialog,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('albums').orderBy('createdAt').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          var albums = snapshot.data!.docs;

          if (albums.isEmpty) {
            return Center(child: Text('No hay álbumes creados.'));
          }

          // Actualizar el caché local
          for (var album in albums) {
            _albumsBox.put(album.id, {
              'name': album['name'],
              'createdAt': album['createdAt']?.toDate()?.toIso8601String() ?? DateTime.now().toIso8601String(),
            });
          }

          return GridView.builder(
            padding: EdgeInsets.all(10.0),
            itemCount: albums.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Puedes ajustar el número de columnas
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
              childAspectRatio: 0.8, // Ajusta la proporción para adaptarse a la imagen y el texto
            ),
            itemBuilder: (context, index) {
              var album = albums[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AlbumPhotosPage(
                        albumId: album.id,
                        albumName: album['name'],
                      ),
                    ),
                  );
                },
                child: Card(
                  elevation: 4.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: FutureBuilder<QuerySnapshot>(
                          future: _firestore
                              .collection('photos')
                              .where('albumId', isEqualTo: album.id)
                              .orderBy('timestamp', descending: true)
                              .limit(1)
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                              var photoData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                              String imageUrl = photoData['imageUrl'];
                              return CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) => Icon(Icons.image, size: 50),
                              );
                            } else {
                              return Icon(Icons.image_not_supported, size: 50);
                            }
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          album['name'],
                          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _showEditAlbumDialog(album),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteAlbum(album),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}