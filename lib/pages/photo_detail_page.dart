// photo_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_photo_page.dart';
import 'full_image_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class PhotoDetailPage extends StatelessWidget {
  final DocumentReference<Object?> photoRef;

  const PhotoDetailPage({Key? key, required this.photoRef}) : super(key: key);

  void _moveToAlbum(BuildContext context, Map<String, dynamic> photoData) async {
    // Obtener la lista de álbumes
    var albumsSnapshot = await FirebaseFirestore.instance
        .collection('albums')
        .orderBy('createdAt')
        .get();

    var albums = albumsSnapshot.docs;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: albums.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return ListTile(
                title: Text('Sin Álbum'),
                onTap: () {
                  photoRef.update({'albumId': null});
                  Navigator.of(context).pop();
                },
              );
            } else {
              var album = albums[index - 1];
              return ListTile(
                title: Text(album['name']),
                onTap: () {
                  photoRef.update({'albumId': album.id});
                  Navigator.of(context).pop();
                },
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles de la foto'),
      ),
      body: StreamBuilder<DocumentSnapshot<Object?>>(
        stream: photoRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar la foto.'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('La foto no existe.'));
          }

          var photoData = snapshot.data!.data() as Map<String, dynamic>;
          String imageUrl = photoData['imageUrl'] ?? '';
          String description = photoData['description'] ?? '';
          List<dynamic> tags = photoData['tags'] ?? [];
          Timestamp timestamp = photoData['timestamp'] ?? Timestamp.now();
          String formattedDate =
          DateFormat('dd/MM/yyyy').format(timestamp.toDate());
          bool isFavorite = photoData['isFavorite'] ?? false;
          String? albumId = photoData['albumId'];

          return FutureBuilder<DocumentSnapshot>(
            future: albumId != null
                ? FirebaseFirestore.instance
                .collection('albums')
                .doc(albumId)
                .get()
                : null,
            builder: (context, albumSnapshot) {
              String albumName = 'Sin Álbum';
              if (albumId != null && albumSnapshot.hasData && albumSnapshot.data!.exists) {
                albumName = albumSnapshot.data!['name'];
              }

              return SingleChildScrollView(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Navegar a la página para ver la imagen en pantalla completa
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullImagePage(imageUrl: imageUrl),
                          ),
                        );
                      },
                      child: Hero(
                        tag: photoRef.id,
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          placeholder: (context, url) =>
                              Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) {
                            return Column(
                              children: [
                                Icon(Icons.broken_image, size: 100),
                                SizedBox(height: 16),
                                Text('No se pudo cargar la imagen'),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        description,
                        style: TextStyle(fontSize: 18.0),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    Wrap(
                      spacing: 8.0,
                      children: tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      'Fecha: $formattedDate',
                      style: TextStyle(fontSize: 16.0),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Álbum: $albumName',
                      style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16.0),
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: Colors.red,
                        size: 32,
                      ),
                      onPressed: () {
                        _toggleFavorite(photoRef, isFavorite);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  void _toggleFavorite(DocumentReference photoRef, bool currentStatus) async {
    try {
      await photoRef.update({'isFavorite': !currentStatus});
    } catch (e) {
      print('Error al actualizar isFavorite: $e');
      // Puedes mostrar un mensaje de error al usuario si lo deseas
    }
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Object?>>(
      stream: photoRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Container();
        }

        var photoData = snapshot.data!.data() as Map<String, dynamic>;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'move',
              onPressed: () => _moveToAlbum(context, photoData),
              child: Icon(Icons.album),
            ),
            SizedBox(height: 16.0),
            FloatingActionButton(
              heroTag: 'edit',
              onPressed: () {
                // Navegar a la página de edición
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditPhotoPage(photoRef: photoRef),
                  ),
                );
              },
              child: Icon(Icons.edit),
            ),
            SizedBox(height: 16.0),
            FloatingActionButton(
              heroTag: 'delete',
              backgroundColor: Colors.red,
              onPressed: () async {
                // Confirmar eliminación
                bool confirm = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Eliminar foto'),
                    content: Text(
                        '¿Estás seguro de que deseas eliminar esta foto? Esta acción no se puede deshacer.'),
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
                  // Eliminar el documento de Firestore
                  await photoRef.delete();

                  // Regresar a la pantalla anterior
                  Navigator.pop(context);
                }
              },
              child: Icon(Icons.delete),
            ),
          ],
        );
      },
    );
  }
}
