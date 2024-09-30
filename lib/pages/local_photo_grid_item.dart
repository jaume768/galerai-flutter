// local_photo_grid_item.dart

import 'package:flutter/material.dart';
import 'full_image_page.dart';
import 'dart:io';

class LocalPhotoGridItem extends StatelessWidget {
  final Map<String, dynamic> localPhoto;

  const LocalPhotoGridItem({Key? key, required this.localPhoto})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    String? localPath = localPhoto['localPath'];

    if (localPath == null || localPath.isEmpty) {
      return SizedBox.shrink(); // No muestra nada
    }

    return GestureDetector(
      onTap: () {
        // Navegar a la página de detalles o imagen completa
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullImagePage(
              imageFile: File(localPath),
              isLocal: true,
            ),
          ),
        );
      },
      child: Hero(
        tag: localPath,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.file(
            File(localPath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
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
    );
  }
}
