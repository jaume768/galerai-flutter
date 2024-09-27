// photo_grid_item.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'photo_detail_page.dart';

typedef OnImageErrorCallback = void Function(String photoId);

class PhotoGridItem extends StatefulWidget {
  final QueryDocumentSnapshot photo;
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
            builder: (context) => PhotoDetailPage(photoRef: widget.photo.reference),
          ),
        );
      },
      child: Hero(
        tag: widget.photo.id,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              // Notificar el error al padre
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.onImageError(widget.photo.id);
              });
              return SizedBox.shrink(); // No muestra nada
            },
          ),
        ),
      ),
    );
  }
}
