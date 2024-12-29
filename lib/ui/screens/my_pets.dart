import 'package:flutter/material.dart';

class MyPetsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pets'),
      ),
      body: const Center(
        child: Text('This is My Pets page'),
      ),
    );
  }
}