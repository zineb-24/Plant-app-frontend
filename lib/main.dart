import 'package:flutter/material.dart';
import 'ui/widgets/bottom_menu.dart';
import 'ui/screens/login.dart';
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
    try {
      final credentials = await storage.read(key: 'credentials');
      print('Stored credentials: ${credentials != null ? "Found" : "Not found"}');
      
      if (credentials != null) {
        await fetchUserDetails();
      } else {
        setState(() => isLoggedIn = false);
      }
    } catch (e) {
      print('Error checking login status: $e');
      setState(() => isLoggedIn = false);
    }
  }

  Future<void> fetchUserDetails() async {
    try {
      final credentials = await storage.read(key: 'credentials');
      print('Fetching user details with stored credentials');
      
      final url = Uri.parse('http://10.0.2.2:8000/api/user');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Basic $credentials'},
      );

      print('User details response status: ${response.statusCode}');
      print('User details response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await storage.write(key: 'username', value: data['username']);
        setState(() {
          username = data['username'];
          isLoggedIn = true;
        });
        print('Successfully logged in as: $username');
      } else {
        print('Failed to fetch user details, clearing credentials');
        await storage.delete(key: 'credentials');
        setState(() => isLoggedIn = false);
      }
    } catch (e) {
      print('Error fetching user details: $e');
      setState(() => isLoggedIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plant Reminder',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: isLoggedIn
          ? BottomMenu(
              username: username ?? 'User',
            )
          : LoginScreen(
              onLoginSuccess: (credentials) async {
                print('Login success callback triggered');
                await storage.write(key: 'credentials', value: credentials);
                await fetchUserDetails();
              },
            ),
    );
  }
}