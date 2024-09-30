// full_image_page.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

class FullImagePage extends StatelessWidget {
  final String? imageUrl;
  final File? imageFile;
  final bool isLocal;

  const FullImagePage({
    Key? key,
    this.imageUrl,
    this.imageFile,
    this.isLocal = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Imagen Completa'),
      ),
      body: Center(
        child: Hero(
          tag: isLocal ? imageFile!.path : imageUrl!,
          child: isLocal
              ? Image.file(
                  imageFile!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 100),
                        SizedBox(height: 16),
                        Text('No se pudo cargar la imagen'),
                      ],
                    );
                  },
                )
              : CachedNetworkImage(
                  imageUrl: imageUrl!,
                  placeholder: (context, url) =>
                      Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 100),
                      SizedBox(height: 16),
                      Text('No se pudo cargar la imagen'),
                    ],
                  ),
                  fit: BoxFit.contain,
                ),
        ),
      ),
    );
  }
}
