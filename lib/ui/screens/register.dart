import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '/ui/screens/login.dart';

class RegisterScreen extends StatefulWidget {
  final Function(String credentials) onRegisterSuccess;

  const RegisterScreen({required this.onRegisterSuccess, super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final storage = FlutterSecureStorage();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;


Future<void> _register() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  final username = _usernameController.text.trim();
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();

  final url = Uri.parse('http://10.0.2.2:8000/api/register');
  final body = json.encode({'username': username, 'email': email, 'password': password});

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    print("Registration response status: ${response.statusCode}");
    print("Registration response body: ${response.body}");

    if (response.statusCode == 201) {
      // Registration successful
      print("Registration successful. Redirecting to login page.");
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => LoginScreen(
              onLoginSuccess: widget.onRegisterSuccess,
            ),
          ),
        );
      }
    } else if (response.statusCode == 400) {
      // Handle validation errors
      final errors = json.decode(response.body);
      if (errors.containsKey('email')) {
        setState(() {
          _errorMessage = 'Email is already registered.';
        });
      } else {
        setState(() {
          _errorMessage = 'Registration failed. Please try again.';
        });
      }
    } else {
      // Handle other errors
      setState(() {
        _errorMessage = 'Registration failed. Please try again.';
      });
    }
  } catch (e) {
    print("Registration error: $e");
    setState(() {
      _errorMessage = 'An error occurred. Please try again.';
    });
  } finally {
    setState(() => _isLoading = false);
  }
}


@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    body: SingleChildScrollView(
      child: Column(
        children: [
          // Curved image at the top
          ClipPath(
            clipper: CurvedBottomClipper(), // Add this class from login.dart
            child: Container(
              height: 300,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('lib/assets/images/leaves_bg.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Register',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E2E2E),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your new account',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                
                // Username Field
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F3F3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      icon: Icon(Icons.person_outline, color: Color(0xFF01A79F)),
                      hintText: 'Username',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Email Field
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F3F3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      icon: Icon(Icons.email_outlined, color: Color(0xFF01A79F)),
                      hintText: 'Email',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Password Field
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F3F3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      icon: const Icon(Icons.lock_outline, color: Color(0xFF01A79F)),
                      hintText: 'Password',
                      hintStyle: const TextStyle(color: Colors.grey),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: TextButton(
                    onPressed: _isLoading ? null : _register,
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF01A79F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Register',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Color(0xFF01A79F),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 50,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}