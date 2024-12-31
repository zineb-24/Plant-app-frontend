import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';
import '/ui/screens/site_plant_list.dart';
import '/ui/screens/add_site.dart';
import '/ui/screens/search_plants.dart';

class MyPlantsPage extends StatefulWidget {
  const MyPlantsPage({super.key});

  @override
  MyPlantsPageState createState() => MyPlantsPageState();
}

class MyPlantsPageState extends State<MyPlantsPage> {
  final storage = FlutterSecureStorage();
  List<dynamic> plants = [];
  List<dynamic> sites = [];
  bool isLoading = true;
  bool isSitesLoading = true;
  String? errorMessage;
  int selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchPlants();
    fetchSites();
  }

  Future<void> fetchPlants() async {
    try {
      setState(() => isLoading = true);
      final credentials = await storage.read(key: 'credentials');
      
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/user-plants/'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          plants = json.decode(response.body);
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

  Future<void> fetchSites() async {
    try {
      setState(() => isSitesLoading = true);
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
          sites = json.decode(response.body);
          isSitesLoading = false;
        });
      } else {
        throw Exception('Failed to load sites');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load sites. Please try again.';
        isSitesLoading = false;
      });
    }
  }


String _formatLight(String? light) {
  if (light == null) return 'Unknown';
  switch (light.toLowerCase()) {
    case 'low':
      return 'Low light';
    case 'medium':
      return 'Partial sun';
    case 'high':
      return 'Full sun';
    default:
      return 'Unknown';
  }
}

void _addPlant() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const SearchPlantsPage(),
    ),
  );
}

void _addSite() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AddSitePage(
        onSiteAdded: () {
          fetchSites();
          fetchPlants();
        },
      ),
    ),
  );
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
          duration: const Duration(milliseconds: 200), // Animation duration
          curve: Curves.easeInOut, // Smooth easing curve
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
            duration: const Duration(milliseconds: 200), // Match container animation
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
            'No plants added yet',
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
  return ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    itemCount: plants.length,
    itemBuilder: (context, index) {
      final plant = plants[index];
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),  // Increased padding
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plant Image - Increased size
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: plant['image'] != null
                    ? Image.network(
                        plant['image']?.startsWith('http://localhost') == true
                          ? plant['image']?.replaceFirst('http://localhost', 'http://10.0.2.2')
                          : plant['image'],
                        width: 100,  // Increased from 80
                        height: 100, // Increased from 80
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 100,  // Increased from 80
                          height: 100, // Increased from 80
                          color: Colors.grey[100],
                          child: Icon(Icons.eco, 
                            color: Colors.grey[300],
                            size: 40,  // Increased icon size
                          ),
                        ),
                      )
                    : Container(
                        width: 100,  // Increased from 80
                        height: 100, // Increased from 80
                        color: Colors.grey[100],
                        child: Icon(Icons.eco, 
                          color: Colors.grey[300],
                          size: 40,  // Increased icon size
                        ),
                      ),
              ),
              const SizedBox(width: 16),  // Increased spacing
              // Plant Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant['nickname'] ?? 'Plant name',
                      style: const TextStyle(
                        fontSize: 21,  // Increased from 16
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),  // Increased spacing
                    Text(
                      plant['plant'] != null && plant['plant']['species_name'] != null
                        ? plant['plant']['species_name']
                        : 'Species name',
                      style: TextStyle(
                        fontSize: 17,  // Increased from 14
                        color: const Color.fromARGB(255, 1, 167, 159) ,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 20),  // Increased spacing
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 20,  // Increased from 16
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),  // Increased spacing
                        Text(
                          plant['site'] != null ? plant['site']['name'] : 'No location',
                          style: TextStyle(
                            fontSize: 17,  // Increased from 14
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildSitesList() {
  return ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    itemCount: sites.length,
    itemBuilder: (context, index) {
      final site = sites[index];
      // Get plants in this site
      final sitePlants = plants.where((plant) => 
        plant['site'] != null && plant['site']['id'] == site['id']
      ).toList();
      
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SitePlantListPage(
                site: site,
                onPlantsChanged: () {
                  fetchPlants();
                  fetchSites();
                },
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
            // Add subtle shadow on hover effect
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plant Images Grid
                SizedBox(
                  height: 120,
                  child: Row(
                    children: [
                      ...List.generate(
                        min(4, sitePlants.length), // Show max 4 images
                        (index) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: Hero(
                              tag: 'site-plant-${sitePlants[index]['id']}',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: sitePlants[index]['image'] != null
                                    ? Image.network(
                                        'http://10.0.2.2:8000${sitePlants[index]['image']}',
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          height: 120,
                                          color: Colors.grey[100],
                                          child: Icon(Icons.eco, 
                                            color: Colors.grey[300],
                                            size: 32,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        height: 120,
                                        color: Colors.grey[100],
                                        child: Icon(Icons.eco, 
                                          color: Colors.grey[300],
                                          size: 32,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Fill remaining space with empty containers if less than 4 plants
                      ...List.generate(
                        max(0, 4 - sitePlants.length),
                        (index) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.eco, 
                                color: Colors.grey[300],
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Site Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      site['name'] ?? 'Site name',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Light and Tasks Info
                Row(
                  children: [
                    Icon(Icons.wb_sunny_outlined, 
                      size: 22,
                      color: Color.fromARGB(255, 255, 204, 84),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatLight(site['light']),
                      style: TextStyle(
                        fontSize: 16,
                        color: Color.fromARGB(255, 255, 204, 84),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.eco, 
                      size: 22,
                      color: const Color.fromARGB(255, 1, 167, 159),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${sitePlants.length} ${sitePlants.length == 1 ? "Plant" : "Plants"}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 1, 167, 159),
                      ),
                    ),
                  ],
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
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Plants',
                  style: TextStyle(
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
    body: Column(
      children: [
        // Tab buttons
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
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
                _buildTabButton('Plants', 0),
                _buildTabButton('Sites', 1),
              ],
            ),
          ),
        ),
        // Content
        Expanded(
          child: selectedTabIndex == 0
              ? isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                      ? Center(child: Text(errorMessage!))
                      : plants.isEmpty
                          ? _buildEmptyState()
                          : _buildPlantsList()
              : isSitesLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                      ? Center(child: Text(errorMessage!))
                      : sites.isEmpty
                          ? _buildEmptyState()
                          : _buildSitesList(),
        ),
        // Dynamic Add Button
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                if (selectedTabIndex == 0) {
                  _addPlant(); // Call the add plant method
                } else if (selectedTabIndex == 1) {
                  _addSite(); // Call the add site method
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF01A79F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'lib/assets/icons/plus.png',
                      height: 60,
                      width: 60,
                    ),
                  ),
                  const SizedBox(width: 12), 
                  Text(
                    selectedTabIndex == 0 ? 'Add Plant' : 'Add Site',
                    style: const TextStyle(
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
      ],
    ),
  );
}
}