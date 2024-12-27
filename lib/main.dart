import 'package:flutter/material.dart';
import 'ui/screens/homepage.dart'; // Import the updated homepage screen
import 'ui/screens/login.dart'; // Import the login screen
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp()); // Launch the app by running MyApp
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final FlutterSecureStorage storage = FlutterSecureStorage(); // Secure storage for JWT
  bool isLoggedIn = false; // Track login status
  String? jwtToken;
  String? username; // Store the username

  @override
  void initState() {
    super.initState();
    checkLoginStatus(); // Check if the user is logged in
  }

  Future<void> checkLoginStatus() async {
    jwtToken = await storage.read(key: 'jwt'); // Read JWT from secure storage
    if (jwtToken != null) {
      // User is logged in, fetch user details
      await fetchUserDetails();
    } else {
      setState(() {
        isLoggedIn = false;
      });
    }
  }

  Future<void> fetchUserDetails() async {
    try {
        final url = Uri.parse('http://10.0.2.2:8000/api/user');
        final response = await http.get(
            url,
            headers: {'Authorization': 'Bearer $jwtToken'},
        );

        if (response.statusCode == 200) {
            final data = json.decode(response.body);
            await storage.write(key: 'username', value: data['username']); // Save username
            setState(() {
                username = data['username'];
                isLoggedIn = true;
            });
        } else {
            await storage.delete(key: 'jwt');
            setState(() => isLoggedIn = false);
        }
    } catch (e) {
        setState(() => isLoggedIn = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plant Reminder', // Sets the title of the app
      theme: ThemeData(primarySwatch: Colors.blue), // Defines the app's theme
      home: isLoggedIn
          ? HomePage( // If logged in, show HomePage
              userData: {'username': username ?? 'User'}, // Pass the actual username or a default value
            )
          : LoginScreen( // If not logged in, show LoginScreen
              onLoginSuccess: (token) async {
                await storage.write(key: 'jwt', value: token); // Save JWT to secure storage
                setState(() {
                  jwtToken = token;
                });
                await fetchUserDetails(); // Fetch username after login
              },
            ),
    );
  }
}
