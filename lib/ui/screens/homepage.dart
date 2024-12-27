import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TaskData {
  final List<dynamic> tasks;
  final bool isOverdue;

  TaskData({required this.tasks, required this.isOverdue});
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
            completedTasks = 0;
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
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tasks?.isOverdue == true ? 'Overdue Tasks' : 'Tasks for today',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: tasks?.isOverdue == true ? Colors.red : Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Total tasks: ${tasks?.tasks.length ?? 0}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Image.asset(
            'lib/assets/icons/smiley_plant.png',
            height: 60,
            width: 60,
          ),
        ],
      ),
    );
  }

  Widget _buildNoTasksMessage() {
    return Transform.translate(
      offset: const Offset(0, -60),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'lib/assets/icons/smiley_plant.png',
              height: 100,
              width: 100,
            ),
            const SizedBox(height: 20),
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
        final availableWidth = constraints.maxWidth - (40 * 2 + 10);
        final dateWidth = (availableWidth / 5) - 8;

        return SizedBox(
          height: 80,
          child: Row(
            children: [
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
                        color: isSelected ? const Color(0xFF1FCC97) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isToday 
                            ? const Color(0xFF1FCC97)
                            : Colors.grey.shade200,
                          width: isToday ? 2 : 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: canSelect ? () {
                            final dateStr = DateFormat('yyyy-MM-dd').format(date);
                            final tasks = tasksByDate[dateStr];
                            setState(() {
                              selectedDate = date;
                              if (tasks != null) {
                                totalTasks = tasks.tasks.length;
                                completedTasks = 0;
                              } else {
                                totalTasks = 0;
                                completedTasks = 0;
                              }
                            });
                          } : null,
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
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: _buildDatePicker(),
            ),
            if (isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (totalTasks > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _buildTaskCard(),
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