// login_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage storage = FlutterSecureStorage();

  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';

  bool _isLoading = false;
  String _errorMessage = '';

  Future<bool> loginUser(String username, String password) async {
    var userSnapshot = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    if (userSnapshot.docs.isEmpty) {
      return false;
    }

    var userData = userSnapshot.docs.first.data();
    String salt = userData['salt'];
    String storedPasswordHash = userData['passwordHash'];

    String passwordHash = hashPassword(password, salt);

    if (passwordHash == storedPasswordHash) {
      String userId = userSnapshot.docs.first.id;
      await storage.write(key: 'userId', value: userId);
      return true;
    } else {
      return false;
    }
  }

  String hashPassword(String password, String salt) {
    final key = utf8.encode(password + salt);
    final hash = sha256.convert(key);
    return hash.toString();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      _formKey.currentState!.save();

      bool success = await loginUser(_username, _password);

      setState(() {
        _isLoading = false;
      });

      if (success) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _errorMessage = 'Nombre de usuario o contraseña incorrectos.';
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
                    'Iniciar Sesión',
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
                                color: colorScheme.onSurface.withOpacity(0.7)),
                            filled: true,
                            fillColor: colorScheme.primary.withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(Icons.person,
                                color: colorScheme.onSurface.withOpacity(0.7)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, ingresa tu nombre de usuario';
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
                                color: colorScheme.onSurface.withOpacity(0.7)),
                            filled: true,
                            fillColor: colorScheme.primary.withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(Icons.lock,
                                color: colorScheme.onSurface.withOpacity(0.7)),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, ingresa tu contraseña';
                            }
                            return null;
                          },
                          onSaved: (value) => _password = value!.trim(),
                        ),
                        SizedBox(height: 24.0),
                        // Botón de Iniciar Sesión
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              elevation: 5.0,
                              backgroundColor: Colors.deepPurpleAccent,
                            ),
                            child: Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.0),
                        // Enlace a Registro
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          child: Text(
                            '¿No tienes cuenta? Regístrate',
                            style: TextStyle(color: Colors.deepPurpleAccent),
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
      ),
    );
  }
}
