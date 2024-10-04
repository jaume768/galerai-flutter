// photo_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_photo_page.dart';
import 'full_image_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class PhotoDetailPage extends StatefulWidget {
  final DocumentReference<Object?>? photoRef;
  final Map<String, dynamic>? photoData; // Datos locales desde Hive
  final String? photoId; // Identificador único para Hero animation

  const PhotoDetailPage({
    Key? key,
    this.photoRef,
    this.photoData,
    this.photoId,
  }) : super(key: key);

  @override
  _PhotoDetailPageState createState() => _PhotoDetailPageState();
}

class _PhotoDetailPageState extends State<PhotoDetailPage> {
  Map<String, dynamic>? photoData;
  String? photoId;

  @override
  void initState() {
    super.initState();
    if (widget.photoData != null) {
      photoData = widget.photoData;
      photoId = widget.photoId;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photoRef != null) {
      // Manejar datos desde Firestore
      return Scaffold(
        appBar: AppBar(
          title: Text('Detalles de la foto'),
        ),
        body: StreamBuilder<DocumentSnapshot<Object?>>(
          stream: widget.photoRef!.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error al cargar la foto.'));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text('La foto no existe.'));
            }

            var data = snapshot.data!.data() as Map<String, dynamic>;
            return _buildPhotoDetail(context, data, widget.photoRef);
          },
        ),
        floatingActionButton: _buildFloatingActionButton(context, widget.photoRef),
      );
    } else if (photoData != null) {
      // Manejar datos locales desde Hive
      return Scaffold(
        appBar: AppBar(
          title: Text('Detalles de la foto'),
        ),
        body: _buildPhotoDetail(context, photoData!, null),
        // Puedes deshabilitar el FAB o adaptarlo según tus necesidades
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text('Detalles de la foto'),
        ),
        body: Center(child: Text('No se pudo cargar la foto.')),
      );
    }
  }

  Widget _buildPhotoDetail(BuildContext context, Map<String, dynamic> data, DocumentReference<Object?>? photoRef) {
    String imageUrl = data['imageUrl'] ?? '';
    String description = data['description'] ?? '';
    List<dynamic> tags = data['tags'] ?? [];
    DateTime timestamp;

    if (data['timestamp'] is Timestamp) {
      timestamp = (data['timestamp'] as Timestamp).toDate();
    } else if (data['timestamp'] is DateTime) {
      timestamp = data['timestamp'];
    } else {
      timestamp = DateTime.now();
    }

    String formattedDate = DateFormat('dd/MM/yyyy').format(timestamp);
    bool isFavorite = data['isFavorite'] ?? false;
    String? albumId = data['albumId'];

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
                  tag: photoRef != null ? photoRef.id : photoId ?? imageUrl,
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
                  if (photoRef != null) {
                    _toggleFavorite(photoRef, isFavorite);
                  } else {
                    // Manejar actualización de favorito si es necesario
                  }
                },
              ),
            ],
          ),
        );
      },
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

  Widget _buildFloatingActionButton(BuildContext context, DocumentReference<Object?>? photoRef) {
    if (photoRef == null) {
      // Si no hay photoRef, no mostramos el FAB
      return Container();
    }

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

  void _moveToAlbum(BuildContext context, Map<String, dynamic> photoData) async {
    String? currentAlbumId = photoData['albumId'];

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
                leading: currentAlbumId == null ? Icon(Icons.check) : null,
                title: Text('Sin Álbum'),
                onTap: () {
                  if (currentAlbumId != null) {
                    widget.photoRef!.update({'albumId': null});
                  }
                  Navigator.of(context).pop();
                },
              );
            } else {
              var album = albums[index - 1];
              return ListTile(
                leading: currentAlbumId == album.id ? Icon(Icons.check) : null,
                title: Text(album['name']),
                onTap: () {
                  if (currentAlbumId != album.id) {
                    widget.photoRef!.update({'albumId': album.id});
                  }
                  Navigator.of(context).pop();
                },
              );
            }
          },
        );
      },
    );
  }
}
