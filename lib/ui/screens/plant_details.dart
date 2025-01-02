import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PlantDetailsPage extends StatefulWidget {
  final Map<String, dynamic> plant;

  const PlantDetailsPage({
    super.key,
    required this.plant,
  });

  @override
  PlantDetailsPageState createState() => PlantDetailsPageState();
}

class PlantDetailsPageState extends State<PlantDetailsPage> {
  final storage = FlutterSecureStorage();
  bool isLoading = true;
  Map<String, dynamic>? plantDetails;
  int selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchPlantDetails();
  }

  final Map<String, Color> taskColors = {
    'watering': const Color(0xFF60D6F4),
    'misting': const Color(0xFFF78D8D),
    'fertilizing': const Color(0xFFF3BB23),
    'pruning': const Color(0xFF18C993),
  };


  Future<void> fetchPlantDetails() async {
    try {
      setState(() => isLoading = true);
      final credentials = await storage.read(key: 'credentials');
      
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/userPlant-details/${widget.plant['id']}/'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          plantDetails = json.decode(response.body);
          print(plantDetails);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load plant details');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// Add this method to handle task completion
Future<void> _showTaskCompletionDialog(int taskId) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
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
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text(
              'Yes',
              style: TextStyle(color: Color(0xFF018882)),
            ),
            onPressed: () {
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
    final credentials = await storage.read(key: 'credentials');
    
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/tasks/$taskId/complete/'),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      if (!mounted) return;
      
      // Refresh plant details to update the UI
      await fetchPlantDetails();
      
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
    } else {
      throw Exception('Failed to complete task');
    }
  } catch (e) {
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

  Widget _buildTabButton(String text, int index) {
    final isSelected = selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTabIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color.fromARGB(255, 1, 167, 159) : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ] : [],
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

 Widget _buildTodaysTasks() {
  if (plantDetails == null || plantDetails!['task_checks']['tasks_due_today'].isEmpty) {
     return const SizedBox();
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4), // Matches the tab's padding
    child: Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Tasks",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          ...plantDetails!['task_checks']['tasks_due_today'].map((task) {
            final String taskName = task['task_name'].toString().toLowerCase();
            final Color backgroundColor = taskColors[taskName] ?? Colors.grey;
            final Color iconColor = backgroundColor.withOpacity(1);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      // Task Icon
                      Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          color: backgroundColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(35),
                        ),
                        child: Center(
                          child: Image.asset(
                            'lib/assets/icons/${taskName}.png',
                            width: 40,
                            height: 40,
                            color: iconColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Task Name and Frequency
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task['task_name'].toString().capitalize(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Every ${task['interval']} ${task['unit']}${task['interval'] > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 112, 112, 112),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Complete Button
                      TextButton(
                        onPressed: () => _showTaskCompletionDialog(task['id']),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF01A79F),
                          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16), // Spacing between tasks
              ],
            );
          }).toList(),
        ],
      ),
    ),
  );
}

Widget _buildCareSchedule() {
  if (plantDetails == null || plantDetails!['tasks'].isEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 50), // Adjust this value to control how low it appears
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // Ensure the content respects the padding
          children: [
            // Add button
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFF01A79F),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: null, // Disabled for now
                icon: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Add a care schedule text
            const Text(
              'Add a care schedule',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF525252),
              ),
            ),
          ],
        ),
      ),
    );
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4), // Matches the tab's padding
    child: Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Care Schedule',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          ...plantDetails!['tasks'].map((task) {
            final String taskName = task['name'].toString().toLowerCase();
            final Color backgroundColor = taskColors[taskName] ?? Colors.grey;
            final Color iconColor = backgroundColor.withOpacity(0.7);

            return Column(
              children: [
                Row(
                  children: [
                    // Task Icon
                    Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        color: backgroundColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(35),
                      ),
                      child: Center(
                        child: Image.asset(
                          'lib/assets/icons/${taskName}.png',
                          width: 40,
                          height: 40,
                          color: iconColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Task Name and Frequency
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task['name'].toString().capitalize(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task['frequency'],
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(255, 112, 112, 112),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16), // Spacing between tasks
              ],
            );
          }).toList(),
        ],
      ),
    ),
  );
}


Widget _buildAboutSection() {
  if (plantDetails == null) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  final plant = plantDetails!['user_plant']['plant'];

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Column(
      children: [
        // Information Section
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 6,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7FA),
                      borderRadius: BorderRadius.circular(35),
                    ),
                    child: const Icon(
                      Icons.wb_sunny_outlined,
                      size: 32,
                      color: Color(0xFF01A79F),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant['preferred_light'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Preferred Light',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7FA),
                      borderRadius: BorderRadius.circular(35),
                    ),
                    child: const Icon(
                      Icons.thermostat,
                      size: 32,
                      color: Color(0xFF01A79F),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant['ideal_temp'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ideal Temperature',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7FA),
                      borderRadius: BorderRadius.circular(35),
                    ),
                    child: const Icon(
                      Icons.local_florist_outlined,
                      size: 32,
                      color: Color(0xFF01A79F),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant['bloom_time'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Bloom Time',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7FA),
                      borderRadius: BorderRadius.circular(35),
                    ),
                    child: Icon(
                      // Dynamically set the icon based on toxicity
                      plant['toxicity']?.toLowerCase() == 'non-toxic'
                          ? Icons.verified_outlined // Non-toxic icon
                          : Icons.warning_amber_outlined, // Toxic icon
                      size: 32,
                      color: plant['toxicity']?.toLowerCase() == 'non-toxic'
                          ? const Color(0xFF4CAF50) // Green for non-toxic
                          : const Color(0xFFFF5722), // Orange for toxic
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant['toxicity'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Toxicity',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Description Section
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 6,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.menu_book_outlined, size: 24, color: Colors.black),
                  SizedBox(width: 8),
                  Text(
                    'Plant Description',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                plant['description'] ?? 'No description available',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 300.0,
                  floating: false,
                  pinned: false,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    background: widget.plant['image'] != null
                        ? Image.network(
                            widget.plant['image']?.startsWith('http://localhost') == true
                                ? widget.plant['image']?.replaceFirst('http://localhost', 'http://10.0.2.2')
                                : widget.plant['image'],
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.eco,
                              size: 100,
                              color: Colors.grey[400],
                            ),
                          ),
                  ),
                  leading: Container(
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.settings, color: Colors.grey),
                        onPressed: null, // Disabled for now
                      ),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.plant['nickname'] ?? 'Plant name',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Specie : ${widget.plant['plant']['species_name']}',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Color.fromARGB(255, 0, 0, 0),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Botanical name : ${widget.plant['plant']['scientific_name']}',
                          style: TextStyle(
                            fontSize: 20,
                            color: const Color(0xFF525252),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 24,
                              color: const Color(0xFF01A79F),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.plant['site'] != null
                                  ? '${widget.plant['site']['name']} - ${widget.plant['site']['location'].toString().capitalize()}'
                                  : 'No location',
                              style: TextStyle(
                                fontSize: 20,
                                color: const Color(0xFF01A79F),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 0,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              _buildTabButton('Care', 0),
                              _buildTabButton('About', 1),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (selectedTabIndex == 0) ...[
                          _buildTodaysTasks(),
                          const SizedBox(height: 20),
                          _buildCareSchedule(),
                        ],
                        if (selectedTabIndex == 1) ...[
                          _buildAboutSection(),
                        ],
                      ],
                    ),
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