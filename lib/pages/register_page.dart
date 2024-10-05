// register_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage storage = FlutterSecureStorage();

  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';
  String _confirmPassword = '';

  bool _isLoading = false;
  String _errorMessage = '';

  String generateSalt() {
    final uuid = Uuid();
    return uuid.v4();
  }

  String hashPassword(String password, String salt) {
    final key = utf8.encode(password + salt);
    final hash = sha256.convert(key);
    return hash.toString();
  }

  Future<bool> registerUser(String username, String password) async {
    var userSnapshot = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      return false;
    }

    String salt = generateSalt();
    String passwordHash = hashPassword(password, salt);
    String userId = Uuid().v4();

    await _firestore.collection('users').doc(userId).set({
      'username': username,
      'passwordHash': passwordHash,
      'salt': salt,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await storage.write(key: 'userId', value: userId);

    return true;
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      _formKey.currentState!.save();

      if (_password != _confirmPassword) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Las contraseñas no coinciden.';
        });
        return;
      }

      bool success = await registerUser(_username, _password);

      setState(() {
        _isLoading = false;
      });

      if (success) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _errorMessage = 'El nombre de usuario ya existe.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ilustración en Pantallas Grandes
              if (MediaQuery.of(context).size.width > 600)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: 24.0),
                    child: Image.asset(
                      'assets/register_illustration.png', // Asegúrate de tener una ilustración adecuada
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              Expanded(
                flex: 1,
                child: Card(
                  color: colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  elevation: 8.0,
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Crear Cuenta',
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 16.0),
                        if (_errorMessage.isNotEmpty)
                          Container(
                            padding: EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error, color: Colors.white),
                                SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    _errorMessage,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(height: 16.0),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Nombre de usuario
                              TextFormField(
                                style: TextStyle(color: colorScheme.onSurface),
                                decoration: InputDecoration(
                                  labelText: 'Nombre de usuario',
                                  labelStyle: TextStyle(
                                      color: colorScheme.onSurface
                                          .withOpacity(0.7)),
                                  filled: true,
                                  fillColor:
                                      colorScheme.primary.withOpacity(0.05),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: Icon(Icons.person_add,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.7)),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor, ingresa un nombre de usuario';
                                  }
                                  return null;
                                },
                                onSaved: (value) => _username = value!.trim(),
                              ),
                              SizedBox(height: 16.0),
                              // Contraseña
                              TextFormField(
                                style: TextStyle(color: colorScheme.onSurface),
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  labelStyle: TextStyle(
                                      color: colorScheme.onSurface
                                          .withOpacity(0.7)),
                                  filled: true,
                                  fillColor:
                                      colorScheme.primary.withOpacity(0.05),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: Icon(Icons.lock_outline,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.7)),
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor, ingresa una contraseña';
                                  }
                                  if (value.length < 6) {
                                    return 'La contraseña debe tener al menos 6 caracteres';
                                  }
                                  return null;
                                },
                                onSaved: (value) => _password = value!.trim(),
                              ),
                              SizedBox(height: 16.0),
                              // Confirmar Contraseña
                              TextFormField(
                                style: TextStyle(color: colorScheme.onSurface),
                                decoration: InputDecoration(
                                  labelText: 'Confirmar Contraseña',
                                  labelStyle: TextStyle(
                                      color: colorScheme.onSurface
                                          .withOpacity(0.7)),
                                  filled: true,
                                  fillColor:
                                      colorScheme.primary.withOpacity(0.05),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: Icon(Icons.lock_outline,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.7)),
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor, confirma tu contraseña';
                                  }
                                  if (value.length < 6) {
                                    return 'La contraseña debe tener al menos 6 caracteres';
                                  }
                                  return null;
                                },
                                onSaved: (value) =>
                                    _confirmPassword = value!.trim(),
                              ),
                              SizedBox(height: 24.0),
                              // Botón de Registro
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _register,
                                  style: ElevatedButton.styleFrom(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 16.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    elevation: 5.0,
                                    backgroundColor: Colors
                                        .deepPurpleAccent, // Color de acento diferente
                                  ),
                                  child: Text(
                                    'Registrar',
                                    style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              SizedBox(height: 12.0),
                              // Enlace a Login
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  '¿Ya tienes una cuenta? Inicia Sesión',
                                  style:
                                      TextStyle(color: Colors.deepPurpleAccent),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
