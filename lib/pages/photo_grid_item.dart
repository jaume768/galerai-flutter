// photo_grid_item.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'photo_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

    if (imageUrl == null || imageUrl.isEmpty) {
      // Notificar que la imagen no es válida
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onImageError(widget.photo.id);
      });
      return SizedBox.shrink(); // No muestra nada
    }

    return _hasError
        ? SizedBox.shrink() // No muestra nada si hubo un error
        : GestureDetector(
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
            child: Hero(
              tag: widget.photo.id,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
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
          );
  }
}
