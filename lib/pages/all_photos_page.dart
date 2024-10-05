// all_photos_page.dart

import 'package:flutter/material.dart';
import 'photo_grid_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AllPhotosPage extends StatefulWidget {
  const AllPhotosPage({Key? key}) : super(key: key);

  @override
  _AllPhotosPageState createState() => _AllPhotosPageState();
}

class _AllPhotosPageState extends State<AllPhotosPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage storage = FlutterSecureStorage();
  final _searchSubject = BehaviorSubject<String>();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Stream<QuerySnapshot<Object?>>? _photosStream;

  // Variables para agregar fotos
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isLoading = false;
  String _errorMessage = '';

  final String backendUrl =
      'https://node-galerai-production.up.railway.app/generate';

  String? userId;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _searchSubject.debounceTime(Duration(milliseconds: 500)).listen((value) {
      setState(() {
        _searchQuery = value.length >= 3 ? value : '';
      });
    });
  }

  Future<void> _initializeUser() async {
    userId = await storage.read(key: 'userId');
    setState(() {
      _photosStream = _firestore
          .collection('photos')
          .where('ownerId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .snapshots();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchSubject.close();
    super.dispose();
  }

  List<QueryDocumentSnapshot<Object?>> _filterPhotos(
      List<QueryDocumentSnapshot<Object?>> photos) {
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

  // Métodos para agregar fotos

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Seleccionar de la Galería'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Tomar Foto'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Si la fuente es la cámara, guardar la imagen en la galería
      if (source == ImageSource.camera) {
        await GallerySaver.saveImage(image.path, albumName: 'GalerAI');
      }

      // Leer la imagen como bytes
      File file = File(image.path);
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
          'isFavorite': false,
          'ownerId': userId, // Añadimos el ownerId
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

  // Fin de métodos para agregar fotos

  @override
  Widget build(BuildContext context) {
    if (_photosStream == null) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _photosStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();

                var photos = _filterPhotos(snapshot.data!.docs);

                if (photos.isEmpty) {
                  return Center(child: Text('No hay fotos subidas.'));
                }

                return GridView.builder(
                  padding: EdgeInsets.all(10.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10.0,
                    mainAxisSpacing: 10.0,
                  ),
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    var photo = photos[index];
                    return PhotoGridItem(
                      photo: photo,
                      onImageError: (id) {},
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showImageSourceActionSheet,
        backgroundColor: Colors.deepPurpleAccent,
        child: Icon(Icons.add_a_photo),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text('Todas las Fotos'),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
