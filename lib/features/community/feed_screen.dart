import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: const Center(child: Text('Community feed coming soon.')),
    );
  }
}
