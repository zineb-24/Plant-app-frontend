import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginScreen extends StatefulWidget {
  final Function(String jwtToken) onLoginSuccess;

  const LoginScreen({required this.onLoginSuccess, super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;


final storage = FlutterSecureStorage(); // Initialize secure storage

Future<void> _login() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  final url = Uri.parse('http://10.0.2.2:8000/api/login');
  final body = {
    'email': _emailController.text.trim(),
    'password': _passwordController.text.trim(),
  };

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final jwtToken = data['jwt'];

      // Save the JWT token securely
      await storage.write(key: 'jwt', value: jwtToken);

      // Pass the token back to the parent widget
      widget.onLoginSuccess(jwtToken);
    } else {
      final errorData = json.decode(response.body);
      setState(() {
        _errorMessage = errorData['detail'] ?? 'Login failed. Please try again.';
      });
    }
  } catch (e) {
    setState(() {
      _errorMessage = 'An error occurred. Please try again later.';
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 24.0),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _login,
                    child: Text('Log In'),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
