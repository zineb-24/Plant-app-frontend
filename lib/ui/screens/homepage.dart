import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const double _dateItemWidth = 53.0; // 45 width + 8 margin
  int completedTasks = 0;
  int totalTasks = 0;
  bool isLoading = true;
  String username = '';

  @override
  void initState() {
    super.initState();
    username = widget.userData['username'] ?? 'User';
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_fadeController);
    fetchTasks();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _animateToDate(bool forward) {
  if (_scrollController.hasClients) {
    final currentOffset = _scrollController.offset;
    final viewportWidth = _scrollController.position.viewportDimension;
    final scrollAmount = viewportWidth + 8; // Add extra space for margins
    
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

  Future<void> fetchTasks() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/tasks/completed/?date=$dateStr'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> completedTasksList = json.decode(response.body);

        final dueTasksResponse = await http.get(
          Uri.parse('http://10.0.2.2:8000/api/tasks/due/'),
          headers: {
            'Authorization': 'Token $token',
            'Content-Type': 'application/json',
          },
        );

        if (dueTasksResponse.statusCode == 200) {
          final data = json.decode(dueTasksResponse.body);
          final dueTasks = data['due_tasks'] as List;

          setState(() {
            completedTasks = completedTasksList.length;
            totalTasks = completedTasksList.length + dueTasks.length;
            isLoading = false;
          });

          if (DateUtils.isSameDay(selectedDate, DateTime.now())) {
            _fadeController.reverse();
          } else {
            _fadeController.forward();
          }
        }
      }
    } catch (e) {
      print('Error fetching tasks: $e');
      setState(() => isLoading = false);
    }
  }

  String _getWeekday(DateTime date) {
    final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return weekdays[date.weekday % 7];
  }

  Widget _buildTaskCard() {
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
                const Text(
                  'Tasks for today',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                if (isLoading)
                  const CircularProgressIndicator()
                else if (totalTasks == 0)
                  Text(
                    'No due tasks for today',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  Text(
                    '$completedTasks of $totalTasks completed',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
              ],
            ),
          ),
          Image.asset(
            'lib/assets/icons/plant_icon.png',
            height: 60,
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate available width
        // Total width minus arrow buttons (40px * 2) and their margins (5px * 2)
        final availableWidth = constraints.maxWidth - (40 * 2 + 10);
        // Calculate date item width accounting for margins
        final dateWidth = (availableWidth / 5) - 8; // Subtract margin space (4px on each side)

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
                        color: isSelected ? const Color(0xFF2ECC71) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isToday 
                            ? const Color(0xFF2ECC71)
                            : Colors.grey.shade200,
                          width: isToday ? 2 : 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: canSelect ? () {
                            setState(() {
                              selectedDate = date;
                            });
                            fetchTasks();
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
      }
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
            color: Colors.white,
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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDatePicker(),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: _fadeAnimation,
                child: DateUtils.isSameDay(selectedDate, DateTime.now())
                    ? _buildTaskCard()
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}