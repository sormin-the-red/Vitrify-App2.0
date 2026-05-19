import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: const Center(child: Text('Your recipes will appear here.')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('New Recipe'),
      ),
    );
  }
}
