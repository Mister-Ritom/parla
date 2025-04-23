import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:parla/screens/chat_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Future<QuerySnapshot>? _searchResults;

  void _searchUsers() {
    final queryText = _searchController.text.trim();
    if (queryText.isNotEmpty) {
      setState(() {
        _searchResults =
            FirebaseFirestore.instance
                .collection('users')
                .where('username', isEqualTo: queryText)
                .get();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by username',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchUsers,
                ),
              ),
              onSubmitted: (_) => _searchUsers(),
            ),
            SizedBox(height: 16),
            Expanded(
              child:
                  _searchResults == null
                      ? Center(child: Text('Enter a username to search'))
                      : FutureBuilder<QuerySnapshot>(
                        future: _searchResults,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }
                          final users = snapshot.data?.docs ?? [];
                          if (users.isEmpty) {
                            return Center(child: Text('No users found'));
                          }
                          final user =
                              users[0]; //There can only be one user with a username
                          return SizedBox(
                            height: 100,
                            child: ListTile(
                              title: Text(user['username']),
                              subtitle: Text(user['name']),
                              onTap: () {
                                // Navigate to the user's profile screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ChatScreen(
                                          userId: user.id,
                                          username: user['username'],
                                        ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
