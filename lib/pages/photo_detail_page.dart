// photo_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'edit_photo_page.dart';
import 'full_image_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PhotoDetailPage extends StatelessWidget {
  final DocumentReference<Object?> photoRef;

  const PhotoDetailPage({Key? key, required this.photoRef}) : super(key: key);

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
              ],
            ),
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
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
  }
}
