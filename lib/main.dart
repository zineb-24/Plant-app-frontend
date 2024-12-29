import 'package:flutter/material.dart';
import 'ui/widgets/bottom_menu.dart'; // Import the BottomMenu widget
import 'ui/screens/login.dart'; // Import the Login screen
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final FlutterSecureStorage storage = FlutterSecureStorage();
  bool isLoggedIn = false;
  String? username;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final credentials = await storage.read(key: 'credentials');
    if (credentials != null) {
      await fetchUserDetails();
    } else {
      setState(() => isLoggedIn = false);
    }
  }

  Future<void> fetchUserDetails() async {
    try {
      final credentials = await storage.read(key: 'credentials');
      final url = Uri.parse('http://10.0.2.2:8000/api/user');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Basic $credentials'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await storage.write(key: 'username', value: data['username']);
        setState(() {
          username = data['username'];
          isLoggedIn = true;
        });
      } else {
        await storage.delete(key: 'credentials');
        setState(() => isLoggedIn = false);
      }
    } catch (e) {
      setState(() => isLoggedIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plant Reminder',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: isLoggedIn
          ? BottomMenu( // Replace HomePage with BottomMenu
              username: username ?? 'User', // Pass username if available
            )
          : LoginScreen(
              onLoginSuccess: (credentials) async {
                await storage.write(key: 'credentials', value: credentials);
                await fetchUserDetails();
              },
            ),
    );
  }
}
