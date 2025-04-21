import 'package:flutter/material.dart';
import 'package:parla/auth/auth_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parla'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              //get auth provider
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              authProvider.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to Parla!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Handle chat navigation
              },
              child: const Text('Start Chatting'),
            ),
          ],
        ),
      ),
    );
  }
}
