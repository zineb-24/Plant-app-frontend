import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';

class MyPetsPage extends StatefulWidget {
  const MyPetsPage({super.key});

  @override
  MyPetsPageState createState() => MyPetsPageState();
}

class MyPetsPageState extends State<MyPetsPage> {
  final storage = FlutterSecureStorage();
  List<dynamic> pets = [];
  List<dynamic> species = [];
  bool isLoading = true;
  bool isSpeciesLoading = true;
  String? errorMessage;
  int selectedTabIndex = 0;
  String? sortOption;

  @override
  void initState() {
    super.initState();
    fetchPets();
    fetchSpecies();
  }

  Future<void> fetchPets() async {
    try {
      setState(() => isLoading = true);
      final credentials = await storage.read(key: 'credentials');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/user-pets/'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          pets = List.from(json.decode(response.body).reversed);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load pets');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load pets. Please try again.';
        isLoading = false;
      });
    }
  }


 Future<void> fetchSpecies() async {
  try {
    setState(() => isSpeciesLoading = true);
    final credentials = await storage.read(key: 'credentials');
    
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/user-pets/species/'),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        species = json.decode(response.body);
        isSpeciesLoading = false;
      });
    } else {
      throw Exception('Failed to load species');
    }
  } catch (e) {
    setState(() {
      errorMessage = 'Failed to load species. Please try again.';
      isSpeciesLoading = false;
    });
  }
}


  void _sortPets() {
    if (sortOption == 'Alphabetical (A-Z)') {
      pets.sort((a, b) => (a['nickname'] ?? '').compareTo(b['nickname'] ?? ''));
    } else if (sortOption == 'Alphabetical (Z-A)') {
      pets.sort((a, b) => (b['nickname'] ?? '').compareTo(a['nickname'] ?? ''));
    } else if (sortOption == 'Last Added') {
      pets.sort((a, b) => b['id'].compareTo(a['id']));
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            selectedTabIndex == 0 ? 'No pets added yet' : 'No species available',
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

  Widget _buildPetsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: pets.length,
      itemBuilder: (context, index) {
        final pet = pets[index];
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
                  child: pet['image'] != null
                    ? Image.network(
                        pet['image']?.startsWith('http://localhost') == true
                          ? pet['image']?.replaceFirst('http://localhost', 'http://10.0.2.2')
                          : pet['image'],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[100],
                          child: Icon(Icons.pets, color: Colors.grey[300], size: 40),
                        ),
                      )
                    : Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[100],
                        child: Icon(Icons.pets, color: Colors.grey[300], size: 40),
                      ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet['nickname'] ?? 'Unnamed Pet',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pet['pet_details']['breed_name'],
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF01A79F),
                        ),
                      ),
                      const SizedBox(height: 17),
                      if (pet['age'] != null)
                        Text(
                          '${pet['age']} ${pet['age'] == 1 ? 'year' : 'years'} old',
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
        );
      },
    );
  }

  Widget _buildSpeciesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: species.length,
      itemBuilder: (context, index) {
        final specie = species[index];
        final speciesPets = pets.where((pet) => 
          pet['pet_details']['species_name'] == specie['species_name']
        ).toList();
        
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
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
                SizedBox(
                  height: 120,
                  child: Row(
                    children: [
                      ...List.generate(
                        min(4, speciesPets.length),
                        (index) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: speciesPets[index]['image'] != null
                                ? Image.network(
                                    speciesPets[index]['image']?.startsWith('http://localhost') == true
                                      ? speciesPets[index]['image']?.replaceFirst('http://localhost', 'http://10.0.2.2')
                                      : speciesPets[index]['image'],
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      height: 120,
                                      color: Colors.grey[100],
                                      child: Icon(Icons.pets, color: Colors.grey[300], size: 32),
                                    ),
                                  )
                                : Container(
                                    height: 120,
                                    color: Colors.grey[100],
                                    child: Icon(Icons.pets, color: Colors.grey[300], size: 32),
                                  ),
                            ),
                          ),
                        ),
                      ),
                      ...List.generate(
                        max(0, 4 - speciesPets.length),
                        (index) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.pets, color: Colors.grey[300], size: 32),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            specie['species_name'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            specie['scientific_name'],
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${speciesPets.length} ${speciesPets.length == 1 ? "Pet" : "Pets"}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF01A79F),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF01A79F) : Colors.transparent,
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

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[100],
    appBar: PreferredSize(
      preferredSize: const Size.fromHeight(70.0),
      child: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('lib/assets/images/pets_bg.png'),
            fit: BoxFit.cover,
            opacity: 0.6,  // Makes the image slightly transparent
          ),
          color: const Color(0xFFFFEAB7),  // Original color acts as an overlay
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
                Row(
                  children: [
                    //const Icon(
                      //Icons.pets,
                      //size: 28,
                      //color: Colors.black,
                    //),
                    const SizedBox(width: 10),
                    const Text(
                      'My Pets',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
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
                _buildTabButton('Pets', 0),
                _buildTabButton('Species', 1),
              ],
            ),
          ),
        ),
        // Sort filter for pets tab
        if (selectedTabIndex == 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sort by:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                DropdownButton<String>(
                  value: sortOption,
                  icon: const Icon(Icons.sort),
                  onChanged: (String? newValue) {
                    setState(() {
                      sortOption = newValue;
                      _sortPets();
                    });
                  },
                  items: <String>['Alphabetical (A-Z)', 'Alphabetical (Z-A)', 'Last Added']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        // Content
        Expanded(
          child: selectedTabIndex == 0
              ? isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                      ? Center(child: Text(errorMessage!))
                      : pets.isEmpty
                          ? _buildEmptyState()
                          : _buildPetsList()
              : isSpeciesLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                      ? Center(child: Text(errorMessage!))
                      : species.isEmpty
                          ? _buildEmptyState()
                          : _buildSpeciesList(),
        ),
        // Add Pet Button
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                // TODO: Implement add pet functionality
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
                    decoration: const BoxDecoration(
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
                  const Text(
                    'Add Pet',
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
      ],
    ),
  );
}
}