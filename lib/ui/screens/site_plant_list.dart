import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SitePlantListPage extends StatefulWidget {
  final Map<String, dynamic> site;
  final VoidCallback onPlantsChanged;

  const SitePlantListPage({
    Key? key,
    required this.site,
    required this.onPlantsChanged,
  }) : super(key: key);

  @override
  SitePlantListPageState createState() => SitePlantListPageState();
}

class SitePlantListPageState extends State<SitePlantListPage> {
  final storage = FlutterSecureStorage();
  List<Map<String, dynamic>> plantsWithTasks = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchSitePlantsAndTasks();
  }

  Future<void> fetchSitePlantsAndTasks() async {
    try {
      setState(() => isLoading = true);
      final credentials = await storage.read(key: 'credentials');
      
      // Fetch plants
      final plantsResponse = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/user-plants/'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
      );

      if (plantsResponse.statusCode == 200) {
        final allPlants = json.decode(plantsResponse.body);
        final sitePlants = allPlants.where((plant) => 
          plant['site'] != null && plant['site']['id'] == widget.site['id']
        ).toList();

        // For each plant, get its tasks
        final List<Map<String, dynamic>> plantsData = [];
        
        for (var plant in sitePlants) {
          final tasksResponse = await http.get(
            Uri.parse('http://10.0.2.2:8000/api/plants/${plant['id']}/tasks/'),
            headers: {
              'Authorization': 'Basic $credentials',
              'Content-Type': 'application/json',
            },
          );

          if (tasksResponse.statusCode == 200) {
            final tasks = json.decode(tasksResponse.body);
            plantsData.add({
              ...plant,
              'taskCount': tasks.length,
            });
          } else {
            plantsData.add({
              ...plant,
              'taskCount': 0,
            });
          }
        }

        setState(() {
          plantsWithTasks = plantsData;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load plants');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load plants. Please try again.';
        isLoading = false;
      });
    }
  }

  Future<void> _showDeleteConfirmation(Map<String, dynamic> plant) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Remove Plant from Site'),
          content: Text(
            'Are you sure you want to remove "${plant['nickname'] ?? 'this plant'}" from ${widget.site['name']}?'
          ),
          actions: [
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Remove',
                style: TextStyle(color: Color(0xFF018882)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _removePlantFromSite(plant);
              },
            ),
          ],
        );
      },
    );
  }

Future<void> _removePlantFromSite(Map<String, dynamic> plant) async {
  try {
    final credentials = await storage.read(key: 'credentials');
    
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/sites/${widget.site['id']}/plants/${plant['id']}/remove/'),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      await fetchSitePlantsAndTasks();
      widget.onPlantsChanged();  // Call the callback to refresh parent page
      
      if (!mounted) return;
      
      final responseData = json.decode(response.body);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(responseData['message']),
          backgroundColor: const Color(0xFF018882),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      throw Exception('Failed to remove plant from site');
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Failed to remove plant from site'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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
            'lib/assets/icons/empty_plant.png',
            height: 160,
            width: 160,
          ),
          const SizedBox(height: 20),
          Text(
            'No plants in this site',
            style: TextStyle(
              fontSize: 18,
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
              padding: const EdgeInsets.fromLTRB(8, 10, 20, 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.site['name'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      // Add site settings navigation here
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : plantsWithTasks.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: plantsWithTasks.length,
                itemBuilder: (context, index) {
                  final plant = plantsWithTasks[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: plant['image'] != null
                                ? Image.network(
                                    'http://10.0.2.2:8000${plant['image']}',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[100],
                                      child: Icon(
                                        Icons.eco,
                                        color: Colors.grey[300],
                                        size: 40,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey[100],
                                    child: Icon(
                                      Icons.eco,
                                      color: Colors.grey[300],
                                      size: 40,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plant['nickname'] ?? plant['plant']['species_name'] ?? 'Plant name',
                                  style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (plant['plant'] != null && plant['plant']['scientific_name'] != null)
                                  Text(
                                    plant['plant']['scientific_name'],
                                    style: const TextStyle(
                                      fontSize: 17,
                                      color: Color.fromARGB(255, 1, 167, 159),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Image.asset(
                                      'lib/assets/icons/task.png',
                                      height: 20,
                                      width: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${plant['taskCount']} ${plant['taskCount'] == 1 ? 'task' : 'tasks'}',
                                      style: TextStyle(
                                        fontSize: 17,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton(
                            icon: const Icon(Icons.more_horiz),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: const Text('Delete from this site'),
                                onTap: () {
                                  Future.delayed(
                                    const Duration(milliseconds: 10),
                                    () => _showDeleteConfirmation(plant),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}