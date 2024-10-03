// albums_page.dart

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

          return ListView.builder(
            itemCount: albums.length,
            itemBuilder: (context, index) {
              var album = albums[index];
              return ListTile(
                title: Text(album['name']),
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
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
              );
            },
          );
        },
      ),
    );
  }
}
