// home_page.dart

import 'package:flutter/material.dart';
import 'photo_detail_page.dart';
import 'photo_grid_item.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Usar BehaviorSubject para debounce
  final _searchSubject = BehaviorSubject<String>();

  final String backendUrl = 'https://node-galerai-production.up.railway.app/generate';

  // Lista de IDs de fotos que han fallado al cargar
  final Set<String> _invalidPhotoIds = {};

  @override
  void initState() {
    super.initState();

    _searchSubject.debounceTime(Duration(milliseconds: 500)).listen((value) {
      setState(() {
        _searchQuery = value.length >= 3 ? value : '';
      });
    });

    _searchFocusNode.addListener(() {
      print('El buscador tiene foco: ${_searchFocusNode.hasFocus}');
    });
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Leer la imagen como bytes
      File file = File(image.path);
      print(file);
      List<int> imageBytes = await file.readAsBytes();

      // Crear una solicitud multipart
      var request = http.MultipartRequest('POST', Uri.parse(backendUrl));

      // Adjuntar la imagen
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: path.basename(image.path),
          contentType: MediaType(
              'image', path.extension(image.path).replaceFirst('.', '')),
        ),
      );

      // Enviar la solicitud
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String description = data['description'];
        List<dynamic> tagsDynamic = data['tags'];
        List<String> tags = tagsDynamic.map((tag) => tag.toString()).toList();

        // Subir la imagen a Firebase Storage
        String fileName =
            '${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
        Reference ref = _storage.ref().child('photos/$fileName');
        SettableMetadata metadata = SettableMetadata(
          contentType:
          'image/${path.extension(image.path).replaceFirst('.', '')}',
        );
        UploadTask uploadTask = ref.putFile(file, metadata);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        // Guardar metadatos en Firestore
        await _firestore.collection('photos').add({
          'imageUrl': downloadUrl,
          'description': description,
          'tags': tags,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        print('Error al llamar al backend: ${response.body}');
        setState(() {
          _errorMessage = 'Error al generar descripción y tags.';
        });
      }
    } catch (e) {
      print(e);
      setState(() {
        _errorMessage = 'Error al subir la imagen.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchSubject.close();
    super.dispose();
  }

  List<QueryDocumentSnapshot> _filterPhotos(List<QueryDocumentSnapshot> photos) {
    if (_searchQuery.isEmpty) {
      return photos;
    } else {
      return photos.where((photo) {
        String description = photo['description'] ?? '';
        List<dynamic> tags = photo['tags'] ?? [];
        String tagsString = tags.join(' ');
        String combined = description + ' ' + tagsString;
        return combined.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  // Callback para manejar errores de carga de imagen
  void _handleImageError(String photoId) {
    setState(() {
      _invalidPhotoIds.add(photoId);
    });
    print('Foto inválida agregada al conjunto: $photoId');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _searchFocusNode.unfocus();
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
          children: [
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('photos')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Error al cargar las fotos'));
                  }
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final photos = snapshot.data!.docs;
                  if (photos.isEmpty) {
                    return Center(child: Text('No hay fotos subidas.'));
                  }
                  final filteredPhotos = _filterPhotos(photos)
                      .where((photo) => !_invalidPhotoIds.contains(photo.id))
                      .toList();

                  print('Total de fotos después del filtrado: ${filteredPhotos.length}');

                  if (filteredPhotos.isEmpty) {
                    return Center(child: Text('No hay fotos válidas.'));
                  }
                  return GridView.builder(
                    padding: EdgeInsets.all(10.0),
                    gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                    ),
                    itemCount: filteredPhotos.length,
                    itemBuilder: (context, index) {
                      final photo = filteredPhotos[index];
                      return PhotoGridItem(
                        photo: photo,
                        onImageError: _handleImageError,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _pickAndUploadImage,
          child: Icon(Icons.add_a_photo),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text('GalerAI'),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Buscar por descripción o tags',
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey[800],
              contentPadding: EdgeInsets.all(10.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              _searchSubject.add(value);
            },
          ),
        ),
      ),
    );
  }
}
