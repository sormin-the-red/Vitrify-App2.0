import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Library'),
          actions: [
            IconButton(
              icon: const Icon(Icons.account_circle_outlined),
              onPressed: () => context.push('/profile'),
            ),
          ],
          bottom: const TabBar(tabs: [
            Tab(text: 'Materials'),
            Tab(text: 'Learn'),
          ]),
        ),
        body: const TabBarView(children: [
          Center(child: Text('Materials reference (1000+ materials) coming soon.')),
          Center(child: Text('Glaze fundamentals and articles coming soon.')),
        ]),
      ),
    );
  }
}
