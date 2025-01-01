import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SiteSettingsPage extends StatefulWidget {
  final Map<String, dynamic> site;
  final VoidCallback onSiteChanged;

  const SiteSettingsPage({
    super.key,
    required this.site,
    required this.onSiteChanged,
  });

  @override
  SiteSettingsPageState createState() => SiteSettingsPageState();
}

class SiteSettingsPageState extends State<SiteSettingsPage> {
  final storage = FlutterSecureStorage();
  final TextEditingController nameController = TextEditingController();
  String selectedLight = 'medium';
  String selectedLocation = 'indoor';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.site['name'];
    selectedLight = widget.site['light'];
    selectedLocation = widget.site['location'];
  }

  Future<void> _updateSite() async {
    setState(() => isLoading = true);
    
    try {
      final credentials = await storage.read(key: 'credentials');
      
      final response = await http.put(
        Uri.parse('http://10.0.2.2:8000/api/sites/${widget.site['id']}/'),
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

      if (response.statusCode == 200) {
        final updatedSite = json.decode(response.body);
        widget.site['name'] = updatedSite['name'];
        widget.site['light'] = updatedSite['light'];
        widget.site['location'] = updatedSite['location'];
        widget.onSiteChanged();
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Site updated successfully'),
            backgroundColor: const Color(0xFF018882),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        throw Exception('Failed to update site');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteSite() async {
    try {
      final credentials = await storage.read(key: 'credentials');
      
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:8000/api/sites/${widget.site['id']}/'),
        headers: {
          'Authorization': 'Basic $credentials',
        },
      );

      if (response.statusCode == 204) {
        widget.onSiteChanged();
        if (!mounted) return;
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Site deleted successfully'),
            backgroundColor: const Color(0xFF018882),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        throw Exception('Failed to delete site');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmation() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Delete Site'),
          content: Text(
            'Are you sure you want to delete "${widget.site['name']}"? This cannot be undone.'
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
                _deleteSite();
              },
            ),
          ],
        );
      },
    );
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
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
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
                      'Site Settings',
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
                      value: nameController.text,
                      onTap: () async {
                        final result = await showDialog<String>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Edit Name'),
                            content: TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                hintText: 'Enter site name',
                              ),
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: isLoading ? null : _updateSite,
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
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE13857),
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
                    onTap: _showDeleteConfirmation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'lib/assets/icons/trash-bin.png',
                            height: 18,
                            width: 18,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Delete site',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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