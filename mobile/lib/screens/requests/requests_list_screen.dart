import 'package:flutter/material.dart';

class RequestsListScreen extends StatelessWidget {
  const RequestsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Requests')),
      body: const Center(
        child: Text('Requests list will be displayed here'),
      ),
    );
  }
}

