// full_image_page.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FullImagePage extends StatelessWidget {
  final String imageUrl;

  const FullImagePage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Imagen Completa'),
      ),
      body: Center(
        child: Hero(
          tag: imageUrl, // Asegúrate de que el tag sea único
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            placeholder: (context, url) =>
                Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) =>
                Icon(Icons.broken_image, size: 100),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
