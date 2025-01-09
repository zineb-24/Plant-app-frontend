import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  CalendarPageState createState() => CalendarPageState();
}

class CalendarPageState extends State<CalendarPage> {
  final storage = FlutterSecureStorage();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<dynamic> completedTasks = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    fetchCompletedTasks(_selectedDay!);
  }

  Future<void> fetchCompletedTasks(DateTime date) async {
    setState(() => isLoading = true);
    try {
      final credentials = await storage.read(key: 'credentials');
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/tasks/completed/$dateStr/'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          completedTasks = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

Widget _buildEmptyState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'lib/assets/icons/smiley_plant.png',
          height: 80,
          width: 80,
        ),
        const SizedBox(height: 20),
        Text(
          'No tasks completed on this day',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ),
  );
}

  @override
Widget build(BuildContext context) {
  final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
  
  return Scaffold(
    backgroundColor: Colors.grey[100],
    appBar: PreferredSize(
      preferredSize: const Size.fromHeight(70.0),
      child: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('lib/assets/images/plants_header.jpg'),
            fit: BoxFit.cover,
            opacity: 0.6,
          ),
          color: const Color(0xFFFFEAB7),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 28,
                  color: Colors.black,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Calendar',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    body: Column(
      children: [
        Card(
          margin: const EdgeInsets.all(20),
          elevation: 2,
          color: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: TableCalendar(
            firstDay: oneYearAgo,
            lastDay: DateTime.now(),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                fetchCompletedTasks(selectedDay);
              }
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF01A79F),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: const Color(0xFF01A79F).withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : completedTasks.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: completedTasks.length,
                      itemBuilder: (context, index) {
                        final task = completedTasks[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            title: Text(
                              task['task_name'].toString().capitalize(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  task['plant_name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF01A79F),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Completed at ${DateFormat('HH:mm').format(DateTime.parse(task['completed_at']))}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF01A79F).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Icon(
                                Icons.check_circle,
                                color: const Color(0xFF01A79F),
                                size: 30,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    ),
  );
}
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}