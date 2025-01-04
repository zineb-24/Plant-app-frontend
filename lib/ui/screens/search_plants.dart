import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '/ui/screens/add_user_plant_form.dart';

class SearchPlantsPage extends StatefulWidget {
  const SearchPlantsPage({super.key});

  @override
  SearchPlantsPageState createState() => SearchPlantsPageState();
}

class SearchPlantsPageState extends State<SearchPlantsPage> {
  final storage = FlutterSecureStorage();
  final TextEditingController searchController = TextEditingController();
  List<dynamic> plants = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchInitialPlants();
  }

  Future<void> fetchInitialPlants() async {
    try {
      setState(() => isLoading = true);
      final credentials = await storage.read(key: 'credentials');
      
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/plants/'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          plants = json.decode(response.body).take(10).toList();
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

  Future<void> searchPlants(String query) async {
    try {
      setState(() => isLoading = true);
      final credentials = await storage.read(key: 'credentials');
      
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/plants/?search=$query'),
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
        throw Exception('Failed to search plants');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to search plants. Please try again.';
        isLoading = false;
      });
    }
  }

Widget _buildNoResultsMessage() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'lib/assets/icons/smiley_plant.png', // Use your empty state icon
          height: 90,
          width: 90,
        ),
        const SizedBox(height: 20),
        Text(
          'No plants found',
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
                const Expanded(
                  child: Text(
                    'Search Plants',
                    style: TextStyle(
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
        Padding(
          padding: const EdgeInsets.all(20),
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
            child: TextField(
              controller: searchController,
              onChanged: (query) {
                if (query.isEmpty) {
                  fetchInitialPlants();
                } else {
                  searchPlants(query);
                }
              },
              decoration: InputDecoration(
                hintText: 'Plant name',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 18),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 25),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
          ),
        ),
        Expanded(
          child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : plants.isEmpty
                ? _buildNoResultsMessage()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: plants.length,
                    itemBuilder: (context, index) {
                      final plant = plants[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
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
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(40),
                                child: plant['image'] != null
                                  ? Image.network(
                                      plant['image'],
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[100],
                                        child: Icon(Icons.image, color: Colors.grey[400], size: 30),
                                      ),
                                    )
                                  : Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey[100],
                                      child: Icon(Icons.image, color: Colors.grey[400], size: 30),
                                    ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      plant['species_name'],
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      plant['scientific_name'],
                                      style: TextStyle(
                                        fontSize: 17,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddUserPlantForm(
                                          plantSpecies: plant,
                                        ),
                                      ),
                                    ).then((added) {
                                      if (added == true) {
                                        Navigator.pop(context, true); // Return true to indicate a new plant was added
                                      }
                                    });
                                  },
                                  child: Ink(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF01A79F),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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