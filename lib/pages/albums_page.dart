// albums_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'album_photos_page.dart';

class AlbumsPage extends StatefulWidget {
  const AlbumsPage({Key? key}) : super(key: key);

  @override
  _AlbumsPageState createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _albumNameController = TextEditingController();

  void _createAlbum() async {
    String albumName = _albumNameController.text.trim();
    if (albumName.isEmpty) return;

    await _firestore.collection('albums').add({
      'name': albumName,
      'createdAt': FieldValue.serverTimestamp(),
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
          if (!snapshot.hasData) return CircularProgressIndicator();

          var albums = snapshot.data!.docs;

          if (albums.isEmpty) {
            return Center(child: Text('No hay álbumes creados.'));
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
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _showEditAlbumDialog(album),
                ),
              );
            },
          );
        },
      ),
    );
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
            onPressed: () {
              String newName = _albumNameController.text.trim();
              if (newName.isNotEmpty) {
                album.reference.update({'name': newName});
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
}
