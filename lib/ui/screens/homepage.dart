import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '/ui/widgets/filter_buttons.dart'; 


class TaskData {
  final List<dynamic> tasks;
  final bool isOverdue;

  TaskData({required this.tasks, required this.isOverdue}) {
    // Sort tasks by completion status
    tasks.sort((a, b) => (a['is_completed'] == b['is_completed']) 
        ? 0 
        : (a['is_completed'] ? 1 : -1));
  }
}

class HomePage extends StatefulWidget {
  final Map<String, String> userData;

  const HomePage({super.key, required this.userData});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  DateTime selectedDate = DateTime.now();
  DateTime startDate = DateTime.now();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  static const double _dateItemWidth = 53.0;
  int completedTasks = 0;
  int totalTasks = 0;
  bool isLoading = true;
  String username = '';
  Map<String, TaskData> tasksByDate = {};

  @override
  void initState() {
    super.initState();
    username = widget.userData['username'] ?? 'User';
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_fadeController);
    fetchAllTasks();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

Future<void> _showTaskCompletionDialog(int taskId) async {
  print('Dialog method called for task: $taskId'); // Debug print
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // User must tap a button to close dialog
    builder: (BuildContext context) {
      print('Building dialog for task: $taskId'); // Debug print
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text('Task Completion'),
        content: const Text('Did you complete this task?'),
        actions: <Widget>[
          TextButton(
            child: const Text('No', style: TextStyle(color: Colors.grey)),
            onPressed: () {
              print('No pressed'); // Debug print
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text(
              'Yes',
              style: TextStyle(color: Color(0xFF018882)),
            ),
            onPressed: () {
              print('Yes pressed for task: $taskId'); // Debug print
              Navigator.of(context).pop();
              _completeTask(taskId);
            },
          ),
        ],
      );
    },
  );
}

Future<void> _completeTask(int taskId) async {
  try {
    print('Completing task with ID: $taskId'); // Debug print
    final storage = FlutterSecureStorage();
    final credentials = await storage.read(key: 'credentials') ?? '';

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/tasks/$taskId/complete/'),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/json',
      },
    );

    print('Response status: ${response.statusCode}'); // Debug print
    print('Response body: ${response.body}'); // Debug print

    if (response.statusCode == 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Task completed successfully!'),
          backgroundColor: const Color(0xFF018882),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      
      await fetchAllTasks();
    } else {
      throw Exception('Failed to complete task: ${response.statusCode}');
    }
  } catch (e) {
    print('Error completing task: $e'); // Debug print
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

  Future<void> fetchAllTasks() async {
    setState(() => isLoading = true);

    try {
      final storage = FlutterSecureStorage();
      final credentials = await storage.read(key: 'credentials') ?? '';

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/tasks/homepage-tasks/'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Tasks data: $data'); //debug line
        final tasksData = data['tasks_by_date'] as Map<String, dynamic>;
        
        tasksByDate.clear();
        tasksData.forEach((date, value) {
          final taskData = value as Map<String, dynamic>;
          tasksByDate[date] = TaskData(
            tasks: taskData['due_tasks'] as List<dynamic>,
            isOverdue: taskData['overdue'] as bool,
          );
        });

        final currentDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
        final currentTasks = tasksByDate[currentDateStr];
        if (currentTasks != null) {
          setState(() {
            totalTasks = currentTasks.tasks.length;
            completedTasks = currentTasks.tasks.where((task) => task['is_completed'] == true).length;
          });
        }
      }
      } catch (e) {
        print('Error fetching tasks: $e');
      } finally {
        setState(() => isLoading = false);
      }
  }

  void _animateToDate(bool forward) {
    if (_scrollController.hasClients) {
      final currentOffset = _scrollController.offset;
      final viewportWidth = _scrollController.position.viewportDimension;
      final scrollAmount = viewportWidth + 8;
      
      _scrollController.animateTo(
        forward ? currentOffset + scrollAmount : currentOffset - scrollAmount,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canSelectDate(DateTime date) {
    DateTime now = DateTime.now();
    DateTime oneMonthFromNow = DateTime(now.year, now.month + 1, now.day);
    return !date.isBefore(DateTime(now.year, now.month, now.day)) && 
           !date.isAfter(oneMonthFromNow);
  }

  String _getWeekday(DateTime date) {
    final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return weekdays[date.weekday % 7];
  }

Widget _buildTaskCard() {
  final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
  final tasks = tasksByDate[dateStr];
  final isToday = DateUtils.isSameDay(selectedDate, DateTime.now());
  
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 5,
        ),
      ],
      image: DecorationImage(
        image: AssetImage('lib/assets/icons/leaves_bg.jpg'),
        fit: BoxFit.cover,
        opacity: 0.8,
      ),
    ),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tasks?.isOverdue == true 
                    ? 'Overdue Tasks' 
                    : isToday 
                      ? 'Tasks for today'
                      : DateFormat('MMMM d').format(selectedDate),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: tasks?.isOverdue == true ? Colors.red : Colors.black,
                    shadows: [
                      Shadow(
                        blurRadius: 2,
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$completedTasks task${completedTasks != 1 ? 's' : ''} completed out of ${tasks?.tasks.length ?? 0}',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    shadows: [
                      Shadow(
                        blurRadius: 2,
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.01),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              'lib/assets/icons/cat.png',
              height: 60,
              width: 60,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildTaskList() {
  final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
  final tasks = tasksByDate[dateStr];
  final isToday = DateUtils.isSameDay(selectedDate, DateTime.now());

  if (tasks == null || tasks.tasks.isEmpty) {
    return const SizedBox.shrink();
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ...tasks.tasks.fold<Map<String, List<dynamic>>>(
        {},
        (map, task) {
          if (!map.containsKey(task['task_name'])) {
            map[task['task_name']] = [];
          }
          map[task['task_name']]!.add(task);
          return map;
        }
      ).entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                entry.key.toString()[0].toUpperCase() + entry.key.toString().substring(1),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...entry.value.map((task) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: task['plant_image'] != null
                          ? Image.network(
                              'http://10.0.2.2:8000${task['plant_image']}',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[200],
                                  child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                                );
                              },
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[200],
                              child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                            ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task['plant_nickname'] ?? 'Unnamed Plant',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  task['site_name'] ?? 'No location',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (task['is_completed'] ?? false)
                        const SizedBox(
                          width: 40,
                          child: Icon(
                            Icons.check_circle,
                            color: Color.fromARGB(255, 1, 167, 159),
                            size: 28,
                          ),
                        )
                      else if (!isToday && selectedDate.isAfter(DateTime.now()))
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          child: TextButton(
                            onPressed: null,
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Done',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          child: TextButton(
                            onPressed: () => _showTaskCompletionDialog(task['id']),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 1, 167, 159),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Done',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            )),
          ],
        );
      }),
    ],
  );
}

   Widget _buildNoTasksMessage() {
    return Transform.translate(
      offset: const Offset(0, -80),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'lib/assets/icons/dog_plant.png',
              height: 160,
              width: 160,
            ),
            const SizedBox(height: 1),
            Text(
              'No due tasks for this day',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildDatePicker() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final availableWidth = constraints.maxWidth - (40 * 2 + 10); // Account for left and right arrows
      final dateWidth = (availableWidth / 5) - 8; // Divide space among 5 items with margins

      return SizedBox(
        height: 80,
        child: Row(
          children: [
            // Left Arrow
            Container(
              width: 40,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.grey),
                onPressed: () => _animateToDate(false),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
            // Date List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: 30,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  final date = DateTime.now().add(Duration(days: index));
                  final isSelected = DateUtils.isSameDay(date, selectedDate);
                  final isToday = DateUtils.isSameDay(date, DateTime.now());
                  final canSelect = _canSelectDate(date);

                  return Container(
                    width: dateWidth,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color.fromARGB(255, 1, 167, 159) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isToday
                            ? const Color.fromARGB(255, 1, 167, 159)
                            : Colors.grey.shade200,
                        width: isToday ? 2 : 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: canSelect
                            ? () {
                                final dateStr = DateFormat('yyyy-MM-dd').format(date);
                                final tasks = tasksByDate[dateStr];
                                setState(() {
                                  selectedDate = date;
                                  if (tasks != null) {
                                    totalTasks = tasks.tasks.length;
                                    completedTasks = tasks.tasks
                                        .where((task) => task['is_completed'] == true)
                                        .length;
                                  } else {
                                    totalTasks = 0;
                                    completedTasks = 0;
                                  }
                                });
                              }
                            : null,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _getWeekday(date),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : canSelect
                                        ? Colors.grey
                                        : Colors.grey.shade300,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('d').format(date),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : canSelect
                                        ? Colors.black
                                        : Colors.grey.shade300,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Right Arrow
            Container(
              width: 40,
              margin: const EdgeInsets.only(left: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.grey),
                onPressed: () => _animateToDate(true),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      );
    },
  );
}


@override
Widget build(BuildContext context) {
  final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
  final tasks = tasksByDate[dateStr];
  final hasTasks = tasks != null && tasks.tasks.isNotEmpty;

  return Scaffold(
    backgroundColor: Colors.grey[100],
    appBar: PreferredSize(
      preferredSize: const Size.fromHeight(70.0),
      child: Container(
        decoration: BoxDecoration(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Welcome, $username!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: const Icon(
                    Icons.person,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Picker Section (always visible)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: _buildDatePicker(),
          ),

          // Conditional Content
          if (isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (hasTasks)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildTaskCard(),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Center(
                    child: FilterButtons(
                      onFilterChanged: (filter) {
                        print('Filter changed to: $filter');
                      },
                    ),
                  ),
                  const SizedBox(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildTaskList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: _buildNoTasksMessage(),
            ),
        ],
      ),
    ),
  );
}
}