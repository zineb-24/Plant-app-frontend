import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '/ui/screens/plant_details.dart';

class EditUserPlantForm extends StatefulWidget {
  final Map<String, dynamic> plant;
  final VoidCallback onPlantUpdated;

  const EditUserPlantForm({
    super.key,
    required this.plant,
    required this.onPlantUpdated,
  });

  @override
  EditUserPlantFormState createState() => EditUserPlantFormState();
}

class EditUserPlantFormState extends State<EditUserPlantForm> {
  final storage = FlutterSecureStorage();
  final TextEditingController nicknameController = TextEditingController();
  File? selectedImage;
  List<Map<String, dynamic>> sites = [];
  Map<String, dynamic>? selectedSite;
  bool isLoading = false;
  Set<String> deletedTasks = {}; // Track which tasks have been marked for deletion
  
  // Task states
  bool wateringEnabled = false;
  bool fertilizingEnabled = false;
  bool mistingEnabled = false;
  bool pruningEnabled = false;
  List<Map<String, dynamic>> existingTasks = [];
  
  // Task frequencies
  Map<String, Map<String, dynamic>> taskFrequencies = {
    'watering': {'interval': 4, 'unit': 'day'},
    'fertilizing': {'interval': 3, 'unit': 'month'},
    'misting': {'interval': 1, 'unit': 'week'},
    'pruning': {'interval': 2, 'unit': 'month'},
  };

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    // Set initial nickname
    nicknameController.text = widget.plant['nickname'] ?? '';
    
    // Set initial site
    if (widget.plant['site'] != null) {
      selectedSite = widget.plant['site'];
    }

    // Fetch existing tasks
    await fetchExistingTasks();
    
    // Fetch available sites
    await fetchSites();
  }

  Future<void> fetchExistingTasks() async {
    try {
      final credentials = await storage.read(key: 'credentials');
      
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/plants/${widget.plant['id']}/tasks/'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final tasks = json.decode(response.body);
        setState(() {
          existingTasks = List<Map<String, dynamic>>.from(tasks);
          
          // Set task states and frequencies based on existing tasks
          for (var task in existingTasks) {
            final taskName = task['name'];
            switch (taskName) {
              case 'watering':
                wateringEnabled = true;
                taskFrequencies['watering'] = {
                  'interval': task['interval'],
                  'unit': task['unit']
                };
                break;
              case 'fertilizing':
                fertilizingEnabled = true;
                taskFrequencies['fertilizing'] = {
                  'interval': task['interval'],
                  'unit': task['unit']
                };
                break;
              case 'misting':
                mistingEnabled = true;
                taskFrequencies['misting'] = {
                  'interval': task['interval'],
                  'unit': task['unit']
                };
                break;
              case 'pruning':
                pruningEnabled = true;
                taskFrequencies['pruning'] = {
                  'interval': task['interval'],
                  'unit': task['unit']
                };
                break;
            }
          }
        });
      }
    } catch (e) {
      print('Error fetching tasks: $e');
    }
  }

  Future<void> fetchSites() async {
    try {
      final credentials = await storage.read(key: 'credentials');
      
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/sites/'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          sites = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      }
    } catch (e) {
      print('Error fetching sites: $e');
    }
  }


  Future<void> _updatePlant() async {
  // Check if any tasks were deleted and show confirmation dialog if needed
  if (deletedTasks.isNotEmpty) {
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Task Deletion'),
          content: Text(
            'Are you sure you want to delete the ${deletedTasks.length} task(s)? '
            'All related history will be lost.'
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (shouldProceed != true) {
      return;
    }
  }

  if (nicknameController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please enter a nickname'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    return;
  }

  setState(() => isLoading = true);

  try {
    final credentials = await storage.read(key: 'credentials');

    // Delete tasks that were marked for deletion
    for (var taskName in deletedTasks) {
      final taskToDelete = existingTasks.firstWhere(
        (task) => task['name'] == taskName,
        orElse: () => {},
      );

      if (taskToDelete.containsKey('id')) {
        final deleteResponse = await http.delete(
          Uri.parse('http://10.0.2.2:8000/api/tasks/${taskToDelete['id']}/delete/'),
          headers: {
            'Authorization': 'Basic $credentials',
          },
        );

        if (deleteResponse.statusCode != 204) {
          throw Exception('Failed to delete task: $taskName');
        }
      }
    }

    // Update plant details
    var request = http.MultipartRequest(
      'PATCH',
      Uri.parse('http://10.0.2.2:8000/api/user-plants/${widget.plant['id']}/'),
    );

    request.headers.addAll({
      'Authorization': 'Basic $credentials',
    });

    request.fields['nickname'] = nicknameController.text;
    if (selectedSite != null) {
      request.fields['site_id'] = selectedSite!['id'].toString();
    }

    if (selectedImage != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        selectedImage!.path,
      ));
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Failed to update plant');
    }

    // Update existing tasks (excluding deleted ones)
    for (var task in existingTasks.where(
      (task) => !deletedTasks.contains(task['name'])
    )) {
      final taskName = task['name'];
      final updatedFrequency = taskFrequencies[taskName];

      if (updatedFrequency?['interval'] != task['interval'] || 
          updatedFrequency?['unit'] != task['unit']) {
        await http.put(
          Uri.parse('http://10.0.2.2:8000/api/tasks/${task['id']}/update/'),
          headers: {
            'Authorization': 'Basic $credentials',
            'Content-Type': 'application/json',
          },
          body: json.encode(updatedFrequency),
        );
      }
    }

    // Add new tasks
    final tasksToAdd = [
      if (wateringEnabled && !existingTasks.any((task) => task['name'] == 'watering'))
        {'name': 'watering', ...taskFrequencies['watering']!},
      if (fertilizingEnabled && !existingTasks.any((task) => task['name'] == 'fertilizing'))
        {'name': 'fertilizing', ...taskFrequencies['fertilizing']!},
      if (mistingEnabled && !existingTasks.any((task) => task['name'] == 'misting'))
        {'name': 'misting', ...taskFrequencies['misting']!},
      if (pruningEnabled && !existingTasks.any((task) => task['name'] == 'pruning'))
        {'name': 'pruning', ...taskFrequencies['pruning']!},
    ];

    for (var task in tasksToAdd) {
      await http.post(
        Uri.parse('http://10.0.2.2:8000/api/plants/${widget.plant['id']}/add-tasks/'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
        body: json.encode(task),
      );
    }

    widget.onPlantUpdated(); // Notify parent widget about the update
    if (!mounted) return;
    Navigator.of(context).pop(true); // Signal success to the parent page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Plant updated successfully!'),
        backgroundColor: const Color(0xFF018882),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  } finally {
    setState(() => isLoading = false);
  }
}


  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

Widget _buildTaskFrequencyItem(
  String taskName,
  String title,
  bool isEnabled,
  String frequency,
  double iconWidth,
  double spacing, // New parameter to customize spacing
) {
  return Column(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Task Icon
            SizedBox(
              width: iconWidth,
              height: iconWidth,
              child: Image.asset(
                'lib/assets/icons/$taskName.png',
                color: const Color(0xFF01A79F),
              ),
            ),
            SizedBox(width: spacing), // Customizable spacing between icon and task name
            // Task Name
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF4E4E4E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Frequency
            Row(
              children: [
                Text(
                  isEnabled ? frequency : 'Not set',
                  style: TextStyle(
                    fontSize: 17,
                    color: isEnabled
                        ? const Color(0xFF4E4E4E)
                        : const Color.fromARGB(255, 133, 133, 133),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ],
        ),
      ),
      // Divider
      const Divider(
        height: 1,
        color: Colors.black12,
        indent: 20, // Optional: Adds padding to the left
        endIndent: 20, // Optional: Adds padding to the right
      ),
    ],
  );
}

void _deleteTask(String taskName) {
  setState(() {
    switch (taskName) {
      case 'watering':
        wateringEnabled = false;
        break;
      case 'fertilizing':
        fertilizingEnabled = false;
        break;
      case 'misting':
        mistingEnabled = false;
        break;
      case 'pruning':
        pruningEnabled = false;
        break;
    }
    deletedTasks.add(taskName);
  });
  
  // Show message that changes will be applied when saving
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Task will be deleted when you save changes'),
      backgroundColor: const Color(0xFF018882),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

  Future<Map<String, dynamic>?> _showFrequencyPicker(String taskName, Map<String, dynamic> currentFrequency) async {
    int interval = currentFrequency['interval'];
    String unit = currentFrequency['unit'];
    
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Set ${taskName.capitalize()} Frequency'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: interval,
                          items: List.generate(30, (i) => i + 1)
                              .map((i) => DropdownMenuItem(
                                    value: i,
                                    child: Text(i.toString()),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => interval = value);
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: 'Interval',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: unit,
                          items: const [
                            DropdownMenuItem(value: 'day', child: Text('Days')),
                            DropdownMenuItem(value: 'week', child: Text('Weeks')),
                            DropdownMenuItem(value: 'month', child: Text('Months')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => unit = value);
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () {
                    _deleteTask(taskName);
                    Navigator.of(context).pop(); // This will just close the frequency picker dialog
                  },
                ),
                TextButton(
                  child: const Text('Save'),
                  onPressed: () => Navigator.of(context).pop({
                    'interval': interval,
                    'unit': unit,
                  }),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatFrequency(Map<String, dynamic> frequency) {
    return 'Every ${frequency['interval']} ${frequency['unit']}${frequency['interval'] > 1 ? 's' : ''}';
  }


Future<void> _editNickname() async {
  final currentNickname = nicknameController.text;
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      String tempNickname = currentNickname;
      return AlertDialog(
        title: const Text('Edit Nickname'),
        content: TextField(
          autofocus: true,
          controller: TextEditingController(text: currentNickname),
          onChanged: (value) => tempNickname = value,
          decoration: const InputDecoration(
            hintText: 'Enter nickname',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                nicknameController.text = tempNickname;
              });
              Navigator.pop(context);
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFF018882),
              ),
            ),
          ),
        ],
      );
    },
  );
}

Future<void> _showImageOptions() async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Change Plant Photo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF01A79F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Color(0xFF01A79F),
                ),
              ),
              title: const Text('Take a photo'),
              onTap: () async {
                Navigator.pop(context);
                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 1800,
                  maxHeight: 1800,
                  imageQuality: 85,
                );
                if (image != null) {
                  setState(() {
                    selectedImage = File(image.path);
                  });
                }
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF01A79F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF01A79F),
                ),
              ),
              title: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(context);
                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 1800,
                  maxHeight: 1800,
                  imageQuality: 85,
                );
                if (image != null) {
                  setState(() {
                    selectedImage = File(image.path);
                  });
                }
              },
            ),
            if (selectedImage != null || widget.plant['image'] != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                ),
                title: const Text('Remove photo'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    selectedImage = null;
                  });
                },
              ),
          ],
        ),
      );
    },
  );
}

Future<void> _showDeleteConfirmation() async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text('Delete Plant'),
        content: Text(
          'Are you sure you want to delete "${widget.plant['nickname'] ?? widget.plant['plant']['species_name']}"? This cannot be undone.'
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _deletePlant();
            },
          ),
        ],
      );
    },
  );
}

Future<void> _deletePlant() async {
  try {
    final credentials = await storage.read(key: 'credentials');
    
    final response = await http.delete(
      Uri.parse('http://10.0.2.2:8000/api/user-plants/${widget.plant['id']}/'),
      headers: {
        'Authorization': 'Basic $credentials',
      },
    );

    if (response.statusCode == 204) {
      if (!mounted) return;
      
      // Pop back to plants list with a result to trigger refresh
      Navigator.of(context).pop(); // Pop edit page
      Navigator.of(context).pop(true); // Pop details page with refresh signal
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Plant deleted successfully'),
          backgroundColor: const Color(0xFF018882),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      throw Exception('Failed to delete plant');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
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
                      'Edit ${widget.plant['nickname'] ?? widget.plant['plant']['species_name']}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plant Info Card
              Container(
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
                child: Column(
                  children: [
                    // Image, nickname and names section
                    InkWell(
                      onTap: _editNickname,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            // Image with edit icon
                            Stack(
                              children: [
                                GestureDetector(
                                  onTap: _showImageOptions,
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(20),
                                      image: selectedImage != null
                                          ? DecorationImage(
                                              image: FileImage(selectedImage!),
                                              fit: BoxFit.cover,
                                            )
                                          : widget.plant['image'] != null
                                              ? DecorationImage(
                                                  image: NetworkImage(widget.plant['image']),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                    ),
                                    child: selectedImage == null && widget.plant['image'] == null
                                        ? Container(
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Icon(
                                              Icons.add_photo_alternate,
                                              size: 40,
                                              color: Colors.grey[400],
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            // Names section
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          nicknameController.text.isNotEmpty 
                                              ? nicknameController.text 
                                              : 'Enter a Nickname',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: nicknameController.text.isNotEmpty 
                                                ? Colors.black87 
                                                : Colors.grey[500],
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: Colors.grey[400],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    widget.plant['plant']['species_name'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: const Color(0xFF4E4E4E),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.plant['plant']['scientific_name'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF4E4E4E),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(height: 1, color: Colors.black12),
                    ),
                    // Site selection
                    InkWell(
                      onTap: () async {
                        final result = await showDialog<Map<String, dynamic>>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Select Site'),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: sites.map((site) => ListTile(
                                  title: Text(site['name']),
                                  subtitle: Text(
                                    '${site['location'].toString().capitalize()} - ${site['light'] == 'low' ? 'Low light' :
                                    site['light'] == 'medium' ? 'Partial sun' : 'Full sun'}'
                                  ),
                                  onTap: () => Navigator.pop(context, site),
                                )).toList(),
                              ),
                            ),
                          ),
                        );
                        if (result != null) {
                          setState(() => selectedSite = result);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 26,
                              color: Color(0xFF01A79F),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Site',
                              style: TextStyle(
                                fontSize: 18,
                                color: const Color.fromARGB(255, 0, 0, 0),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              selectedSite != null ? selectedSite!['name'] : 'Select a site',
                              style: TextStyle(
                                fontSize: 18,
                                color: selectedSite != null ? Colors.black87 : const Color.fromARGB(255, 79, 79, 79),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Care Schedule Section
              Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Icon and Text
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.schedule, // Replace with your desired icon
                            size: 26,
                            color: const Color.fromARGB(255, 0, 0, 0), // Match your theme
                          ),
                          const SizedBox(width: 8), // Space between the icon and text
                          const Text(
                            'Care Schedule',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tasks Section
                    Column(
                      children: [
                        // Watering Task
                        InkWell(
                          onTap: () async {
                            final result = await _showFrequencyPicker(
                              'watering',
                              taskFrequencies['watering']!,
                            );
                            if (result != null) {
                              setState(() {
                                wateringEnabled = true;
                                taskFrequencies['watering'] = result;
                              });
                            }
                          },
                          child: _buildTaskFrequencyItem(
                            'watering',
                            'Watering',
                            wateringEnabled,
                            _formatFrequency(taskFrequencies['watering']!),
                            45.0,
                            20
                          ),
                        ),
                        // Fertilizing Task
                        InkWell(
                          onTap: () async {
                            final result = await _showFrequencyPicker(
                              'fertilizing',
                              taskFrequencies['fertilizing']!,
                            );
                            if (result != null) {
                              setState(() {
                                fertilizingEnabled = true;
                                taskFrequencies['fertilizing'] = result;
                              });
                            }
                          },
                          child: _buildTaskFrequencyItem(
                            'fertilizing',
                            'Fertilizing',
                            fertilizingEnabled,
                            _formatFrequency(taskFrequencies['fertilizing']!),
                            35.0,
                            31
                          ),
                        ),
                        // Misting Task
                        InkWell(
                          onTap: () async {
                            final result = await _showFrequencyPicker(
                              'misting',
                              taskFrequencies['misting']!,
                            );
                            if (result != null) {
                              setState(() {
                                mistingEnabled = true;
                                taskFrequencies['misting'] = result;
                              });
                            }
                          },
                          child: _buildTaskFrequencyItem(
                            'misting',
                            'Misting',
                            mistingEnabled,
                            _formatFrequency(taskFrequencies['misting']!),
                            38.0,
                            27
                          ),
                        ),
                        // Pruning Task
                        InkWell(
                          onTap: () async {
                            final result = await _showFrequencyPicker(
                              'pruning',
                              taskFrequencies['pruning']!,
                            );
                            if (result != null) {
                              setState(() {
                                pruningEnabled = true;
                                taskFrequencies['pruning'] = result;
                              });
                            }
                          },
                          child: _buildTaskFrequencyItem(
                            'pruning',
                            'Pruning',
                            pruningEnabled,
                            _formatFrequency(taskFrequencies['pruning']!),
                            30.0,
                            35
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Update Plant Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: isLoading ? null : _updatePlant,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF01A79F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        //width: 30,
                        //height: 30,
                        //decoration: const BoxDecoration(
                          //color: Colors.white,
                          //shape: BoxShape.circle,
                        //),
                        //child: Image.asset(
                          //'lib/assets/icons/plus.png',
                          //height: 60,
                          //width: 60,
                        //),
                      ),
                      //const SizedBox(width: 12),
                      const Text(
                        'Save changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),  // Add spacing between buttons
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE13857),  // Red color for delete button
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () => _showDeleteConfirmation(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'lib/assets/icons/trash-bin.png',
                            height: 18,
                            width: 18,
                            color: Colors.white,  // Make the icon white
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Delete plant',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

