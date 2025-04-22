import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

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
                labelText: 'Search',
                suffixIcon: Icon(Icons.search),
              ),
            ),

            SizedBox(height: 16),
            Expanded(
              child: FutureBuilder(
                future:
                    supabase
                        .from('profiles')
                        .stream(primaryKey: ['id'])
                        .eq('username', _searchController.text)
                        .order('created_at', ascending: false)
                        .first,

                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No users found'));
                  }

                  final users = snapshot.data;
                  if (users == null || users.isEmpty) {
                    return Center(child: Text('No users found'));
                  }
                  return Text(users.toString());
                  // return ListView.builder(
                  //   itemCount: users.length,
                  //   itemBuilder: (context, index) {
                  //     final user = users[index];
                  //     return ListTile(
                  //       title: Text(user['username']),
                  //       subtitle: Text(user['email']),
                  //     );
                  //   },
                  // );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
