import 'package:flutter/material.dart';

class CreateRequestScreen extends StatelessWidget {
  final String type;

  const CreateRequestScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create ${type.toUpperCase()} Request')),
      body: const Center(
        child: Text('Request creation form will be displayed here'),
      ),
    );
  }
}

