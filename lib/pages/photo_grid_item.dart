// photo_grid_item.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'photo_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

typedef OnImageErrorCallback = void Function(String photoId);

class PhotoGridItem extends StatefulWidget {
  final QueryDocumentSnapshot<Object?> photo;
  final OnImageErrorCallback onImageError;

  const PhotoGridItem({
    Key? key,
    required this.photo,
    required this.onImageError,
  }) : super(key: key);

  @override
  _PhotoGridItemState createState() => _PhotoGridItemState();
}

class _PhotoGridItemState extends State<PhotoGridItem> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    String? imageUrl = widget.photo['imageUrl'];
    Timestamp timestamp = widget.photo['timestamp'] ?? Timestamp.now();
    String formattedDate =
    DateFormat('dd/MM/yyyy').format(timestamp.toDate());
    bool isFavorite = widget.photo['isFavorite'] ?? false;

    if (imageUrl == null || imageUrl.isEmpty) {
      // Notificar que la imagen no es válida
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onImageError(widget.photo.id);
      });
      return SizedBox.shrink(); // No muestra nada
    }

    return GestureDetector(
      onTap: () {
        // Navegar a la pantalla de detalles
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PhotoDetailPage(photoRef: widget.photo.reference),
          ),
        );
      },
      child: Stack(
        children: [
          // Imagen
          Positioned.fill(
            child: Hero(
              tag: widget.photo.id,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                placeholder: (context, url) =>
                    Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) {
                  // Notificar el error al padre
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    widget.onImageError(widget.photo.id);
                  });
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
                _toggleFavorite(widget.photo.reference, isFavorite);
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
    }
  }
}
