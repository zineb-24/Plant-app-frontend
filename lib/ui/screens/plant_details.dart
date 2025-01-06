import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '/ui/screens/edit_user_plant.dart';

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
      final details = json.decode(response.body);
      setState(() {
        plantDetails = details;
        widget.plant['nickname'] = details['user_plant']['nickname']; // Synchronize nickname
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load plant details');
    }
  } catch (e) {
    setState(() => isLoading = false);
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


String _formatFrequency(String frequency) {
  //print('Formatting frequency: $frequency'); // Debug print

  // Convert to lowercase, trim whitespace and remove (s) for consistent comparison
  final normalizedFreq = frequency.toLowerCase().trim().replaceAll('(s)', '');
  
  if (normalizedFreq == 'every 1 day') {
    return 'Everyday';
  } else if (normalizedFreq == 'every 1 week') {
    return 'Every Week';
  } else if (normalizedFreq == 'every 1 month') {
    return 'Every Month';
  }

  // For other frequencies (e.g., "every 2 days", "every 3 weeks", etc.)
  if (frequency.startsWith('every ')) {
    final parts = frequency.split(' ');
    if (parts.length >= 3) {
      final number = parts[1];
      final unit = parts[2].replaceAll('(s)', '');  // Remove (s) from unit
      return 'Every $number ${unit.capitalize()}${number != '1' ? 's' : ''}';
    }
  }
  
  return frequency;
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
                icon: const Icon(Icons.add, color: Color.fromARGB(255, 255, 255, 255)),
                onPressed: () async {
                  final result = await Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => EditUserPlantForm(
                      plant: plantDetails!['user_plant'],
                      onPlantUpdated: fetchPlantDetails, // Pass fetchPlantDetails directly
                    ),
                  ));

                  if (result != null && result == true) {
                    await fetchPlantDetails(); // Ensure data is refreshed
                  }
                },
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
          const SizedBox(height: 35),
          ...plantDetails!['tasks'].map((task) {
            final String taskName = task['name'].toString().toLowerCase();
            final Color backgroundColor = taskColors[taskName] ?? Colors.grey;
            final Color iconColor = backgroundColor.withOpacity(1);

            //print('Raw frequency: ${task['frequency']}'); //debug line

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
                          'lib/assets/icons/$taskName.png',
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
                            _formatFrequency(task['frequency']),
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
                const SizedBox(height: 25), // Spacing between tasks
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
                      color: const Color(0xFFFFBF10).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(35),
                    ),
                    child: Center(
                      child: Image.asset(
                        'lib/assets/icons/sun.png',
                        width: 35,
                        height: 35,
                        color: const Color(0xFFFFBF10),
                      ),
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
                          color: Color(0xFF8B8B8B),
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
                      color: const Color(0xFF60D6F4).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(35),
                    ),
                    child: Center(
                      child: Image.asset(
                        'lib/assets/icons/temperature.png',
                        width: 35,
                        height: 35,
                        color: const Color(0xFF60D6F4),
                      ),
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
                          color: Color(0xFF8B8B8B),
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
                      color: const Color(0xFFFF5722).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(35),
                    ),
                    child: Center(
                      child: Image.asset(
                        'lib/assets/icons/flower.png',
                        width: 30,
                        height: 30,
                        color: const Color(0xFFFF5722),
                      ),
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
                          color: Color(0xFF8B8B8B),
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
                      color: plant['toxicity']?.toLowerCase() == 'non-toxic'
                          ? const Color(0xFF18C993).withOpacity(0.2)
                          : const Color(0xFF18C993).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(35),
                    ),
                    child: Center(
                      child: Image.asset(
                        plant['toxicity']?.toLowerCase() == 'non-toxic'
                            ? 'lib/assets/icons/leaves.png'
                            : 'lib/assets/icons/toxic.png',
                        width: 35,
                        height: 35,
                        color: plant['toxicity']?.toLowerCase() == 'non-toxic'
                            ? const Color(0xFF18C993)
                            : const Color(0xFF18C993),
                      ),
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
                          color: Color(0xFF8B8B8B),
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
                      onPressed: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditUserPlantForm(
                              plant: plantDetails!['user_plant'],
                              onPlantUpdated: () async {
                                await fetchPlantDetails(); // Refresh the details after editing
                              },
                            ),
                          ),
                        ).then((result) async {
                          if (result == true) {
                            // If plant was deleted, pop back to plants list with refresh signal
                            Navigator.of(context).pop(true);
                          }
                        });
                      },
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