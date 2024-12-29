import 'package:flutter/material.dart';
import '/ui/screens/homepage.dart'; // Replace with actual file path
import '/ui/screens/my_plants.dart';
import '/ui/screens/my_pets.dart';
import '/ui/screens/calendar.dart';

class BottomMenu extends StatefulWidget {
  final String username;

  const BottomMenu({super.key, required this.username});

  @override
  _BottomMenuState createState() => _BottomMenuState();
}

class _BottomMenuState extends State<BottomMenu> {
  int _currentIndex = 0;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      HomePage(userData: {'username': widget.username}),
      MyPlantsPage(),
      MyPetsPage(),
      CalendarPage(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.eco), label: 'My Plants'),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'My Pets'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
        ],
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
