// photo_grid_item.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'photo_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

typedef OnImageErrorCallback = void Function(String photoId);

class PhotoGridItem extends StatelessWidget {
  final QueryDocumentSnapshot<Object?>? photo;
  final Map<String, dynamic>? photoData; // Nuevo parámetro para datos locales
  final OnImageErrorCallback onImageError;

  const PhotoGridItem({
    Key? key,
    this.photo,
    this.photoData,
    required this.onImageError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data;

    if (photo != null) {
      data = photo!.data() as Map<String, dynamic>;
    } else if (photoData != null) {
      data = photoData!;
    } else {
      return SizedBox.shrink();
    }

    String? imageUrl = data['imageUrl'];
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

    if (imageUrl == null || imageUrl.isEmpty) {
      // Notificar que la imagen no es válida
      if (photo != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onImageError(photo!.id);
        });
      }
      return SizedBox.shrink(); // No muestra nada
    }

    return GestureDetector(
      onTap: () {
        // Navegar a la pantalla de detalles
        if (photo != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PhotoDetailPage(photoRef: photo!.reference),
            ),
          );
        } else {
          // Manejo para datos locales si es necesario
          // Puedes implementar una versión local de PhotoDetailPage
        }
      },
      child: Stack(
        children: [
          // Imagen
          Positioned.fill(
            child: Hero(
              tag: photo != null ? photo!.id : imageUrl,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                placeholder: (context, url) =>
                    Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) {
                  // Notificar el error al padre
                  if (photo != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      onImageError(photo!.id);
                    });
                  }
                  return SizedBox.shrink(); // No muestra nada
                },
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Fecha
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              color: Colors.black54,
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                formattedDate,
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          // Botón de favorito
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.red,
                size: 24,
              ),
              onPressed: () {
                if (photo != null) {
                  _toggleFavorite(photo!.reference, isFavorite);
                } else {
                  // Manejo para datos locales si es necesario
                }
              },
            ),
          ),
        ],
      ),
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
}
