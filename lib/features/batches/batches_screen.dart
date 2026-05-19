import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BatchesScreen extends StatelessWidget {
  const BatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Batches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: const Center(child: Text('Test batches and tiles will appear here.')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('New Batch'),
      ),
    );
  }
}
