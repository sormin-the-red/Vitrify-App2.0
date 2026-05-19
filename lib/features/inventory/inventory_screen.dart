import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: const Center(child: Text('Your material inventory will appear here.')),
    );
  }
}
