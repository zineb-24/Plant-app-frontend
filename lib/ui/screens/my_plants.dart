import 'package:flutter/material.dart';

class MyPlantsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Plants'),
      ),
      body: const Center(
        child: Text('This is the My Plants page'),
      ),
    );
  }
}