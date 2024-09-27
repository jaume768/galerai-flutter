// edit_photo_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditPhotoPage extends StatefulWidget {
  final DocumentReference photoRef;

  const EditPhotoPage({Key? key, required this.photoRef}) : super(key: key);

  @override
  _EditPhotoPageState createState() => _EditPhotoPageState();
}

class _EditPhotoPageState extends State<EditPhotoPage> {
  late TextEditingController _descriptionController;
  late List<String> _tags;
  bool _isLoading = true;
  String imageUrl = '';

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _tags = [];
    _loadPhotoData();
  }

  Future<void> _loadPhotoData() async {
    var photoSnapshot = await widget.photoRef.get();
    var photoData = photoSnapshot.data() as Map<String, dynamic>;
    setState(() {
      imageUrl = photoData['imageUrl'] ?? '';
      _descriptionController.text = photoData['description'] ?? '';
      _tags = List<String>.from(photoData['tags'] ?? []);
      _isLoading = false;
    });
  }

  void _addTag(String tag) {
    setState(() {
      if (tag.isNotEmpty && !_tags.contains(tag)) {
        _tags.add(tag);
      }
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _saveChanges() async {
    await widget.photoRef.update({
      'description': _descriptionController.text,
      'tags': _tags,
    });
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Editar Foto'),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Foto'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveChanges,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(
              imageUrl,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                  ),
                  SizedBox(height: 16.0),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Tags',
                      style:
                      TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Wrap(
                    spacing: 8.0,
                    children: _tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        onDeleted: () {
                          _removeTag(tag);
                        },
                      );
                    }).toList(),
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Agregar nuevo tag',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      _addTag(value.trim());
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
