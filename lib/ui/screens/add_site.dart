import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AddSitePage extends StatefulWidget {
  final VoidCallback onSiteAdded;

  const AddSitePage({Key? key, required this.onSiteAdded}) : super(key: key);

  @override
  AddSitePageState createState() => AddSitePageState();
}

class AddSitePageState extends State<AddSitePage> {
  final storage = FlutterSecureStorage();
  final TextEditingController nameController = TextEditingController();
  String selectedLight = 'medium';
  String selectedLocation = 'indoor';
  bool isLoading = false;

  Future<void> _addSite() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a site name'),
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
      
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/sites/'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': nameController.text,
          'light': selectedLight,
          'location': selectedLocation,
        }),
      );

      if (response.statusCode == 201) {
        widget.onSiteAdded();
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Site added successfully'),
            backgroundColor: const Color(0xFF018882),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        throw Exception('Failed to add site');
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
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 24),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 18, color: Colors.black87),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
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
                      'Add Site',
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
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
                    _buildSettingItem(
                      icon: Icons.edit_note,
                      label: 'Name',
                      value: nameController.text.isEmpty ? 'Enter site name' : nameController.text,
                      onTap: () async {
                        final result = await showDialog<String>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Enter Name'),
                            content: TextField(
                              controller: nameController,
                              decoration: const InputDecoration(hintText: 'Enter site name'),
                              autofocus: true,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, nameController.text),
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                        );
                        if (result != null) {
                          setState(() {});
                        }
                      },
                    ),
                    const Divider(height: 1),
                    _buildSettingItem(
                      icon: Icons.wb_sunny_outlined,
                      label: 'Light',
                      value: selectedLight == 'low' ? 'Low light' :
                             selectedLight == 'medium' ? 'Partial sun' : 'Full sun',
                      onTap: () async {
                        final result = await showDialog<String>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Select Light Level'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: const Text('Low light'),
                                  onTap: () => Navigator.pop(context, 'low'),
                                ),
                                ListTile(
                                  title: const Text('Partial sun'),
                                  onTap: () => Navigator.pop(context, 'medium'),
                                ),
                                ListTile(
                                  title: const Text('Full sun'),
                                  onTap: () => Navigator.pop(context, 'high'),
                                ),
                              ],
                            ),
                          ),
                        );
                        if (result != null) {
                          setState(() => selectedLight = result);
                        }
                      },
                    ),
                    const Divider(height: 1),
                    _buildSettingItem(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      value: selectedLocation == 'indoor' ? 'Indoor' : 'Outdoor',
                      onTap: () async {
                        final result = await showDialog<String>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Select Location'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: const Text('Indoor'),
                                  onTap: () => Navigator.pop(context, 'indoor'),
                                ),
                                ListTile(
                                  title: const Text('Outdoor'),
                                  onTap: () => Navigator.pop(context, 'outdoor'),
                                ),
                              ],
                            ),
                          ),
                        );
                        if (result != null) {
                          setState(() => selectedLocation = result);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: isLoading ? null : _addSite,
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
                          'Create Site',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}