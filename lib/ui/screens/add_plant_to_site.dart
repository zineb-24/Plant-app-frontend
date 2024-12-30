import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AddSitePlantPage extends StatefulWidget {
  final Map<String, dynamic> site;
  final VoidCallback onPlantAdded;

  const AddSitePlantPage({
    Key? key,
    required this.site,
    required this.onPlantAdded,
  }) : super(key: key);

  @override
  AddSitePlantPageState createState() => AddSitePlantPageState();
}

class AddSitePlantPageState extends State<AddSitePlantPage> {
  final storage = FlutterSecureStorage();
  List<Map<String, dynamic>> availablePlants = [];
  bool isLoading = true;
  Set<int> selectedPlants = {};

  @override
  void initState() {
    super.initState();
    fetchAvailablePlants();
  }

  Future<void> fetchAvailablePlants() async {
  setState(() => isLoading = true);
  try {
    final credentials = await storage.read(key: 'credentials');
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/user-plants/'),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> plants = json.decode(response.body);
      setState(() {
        // Sort the plants so that plants without a site appear first
        availablePlants = plants
            .map((p) => p as Map<String, dynamic>)
            .toList()
          ..sort((a, b) {
            final aHasSite = a['site'] != null;
            final bHasSite = b['site'] != null;
            if (aHasSite && !bHasSite) {
              return 1; // `a` has a site, so it comes after
            } else if (!aHasSite && bHasSite) {
              return -1; // `a` doesn't have a site, so it comes first
            } else {
              return 0; // Both are equal in terms of sorting
            }
          });
        isLoading = false;
      });
    }
  } catch (e) {
    setState(() => isLoading = false);
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

  Future<void> _addPlantsToSite() async {
  if (selectedPlants.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please select at least one plant'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
    return;
  }

  setState(() => isLoading = true);
  try {
    final credentials = await storage.read(key: 'credentials');

    for (var plantId in selectedPlants) {
      final response = await http.patch(
        Uri.parse('http://10.0.2.2:8000/api/user-plants/$plantId/'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'site_id': widget.site['id'], // Send site ID
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to add plant ID $plantId to site ${widget.site['name']}');
      }
    }

    widget.onPlantAdded();
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${selectedPlants.length} plants to ${widget.site['name']}'),
        backgroundColor: const Color(0xFF018882),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  } catch (e) {
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
  } finally {
    setState(() => isLoading = false);
  }
}



  Widget _buildEmptyState() {
    return Center(
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
            'No available plants to add',
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

 Widget _buildPlantsList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final plants = availablePlants.where((plant) => plant['site'] == null).toList();

    if (plants.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: availablePlants.length,
      itemBuilder: (context, index) {
        final plant = availablePlants[index];
        final hasExistingSite = plant['site'] != null;
        final plantId = plant['id'] as int;

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
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Image section
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
                            child: Icon(Icons.eco, color: Colors.grey[300], size: 40),
                          ),
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[100],
                          child: Icon(Icons.eco, color: Colors.grey[300], size: 40),
                        ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plant['nickname'] ?? plant['plant']['species_name'] ?? 'Unnamed Plant',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: hasExistingSite ? Colors.grey : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (plant['plant'] != null && plant['plant']['species_name'] != null)
                          Text(
                            plant['plant']['species_name'],
                            style: TextStyle(
                              fontSize: 16,
                              color: hasExistingSite ? Colors.grey : const Color.fromARGB(255, 1, 167, 159),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 7),
                        if (hasExistingSite)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 18,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${plant['site']['name']}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Checkbox or lock icon
                  if(!hasExistingSite)
                    Transform.scale(
                        scale: 1.2,
                        child: Checkbox(
                          value: selectedPlants.contains(plantId),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedPlants.add(plantId);
                              } else {
                                selectedPlants.remove(plantId);
                              }
                            });
                          },
                          activeColor: const Color(0xFF018882),
                        ),
                      ),
                ],
              ),
            ),
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
            padding: const EdgeInsets.fromLTRB(8, 10, 20, 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    'Add Plants to ${widget.site['name']}',
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
    body: Column(
      children: [
        // Plant list
        Expanded(child: _buildPlantsList()),

        // Conditionally render the Add Selected Plants button
        if (availablePlants.where((plant) => plant['site'] == null).isNotEmpty)
          Transform.translate(
            offset: const Offset(0, -30), // Moves button 10 pixels up
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: isLoading ? null : _addPlantsToSite,
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
                      : const Text(
                          'Add Selected Plants',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

}