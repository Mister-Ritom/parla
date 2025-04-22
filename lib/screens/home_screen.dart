import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:parla/auth/auth_provider.dart';
import 'package:parla/screens/users/profile_screen.dart';
import 'package:parla/screens/users/search_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    //get the user from authProvider
    final user = Provider.of<AuthProvider>(context).nonNullUser;
    return Scaffold(
      appBar: AppBar(
        title: Text('Hello ${user.displayName}'),
        actions: [
          IconButton(
            icon: Icon(FontAwesomeIcons.magnifyingGlass),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          //IconButton of their user photoUrl to view their profile
          IconButton(
            icon:
                user.photoURL == null
                    ? Icon(Icons.person)
                    : CircleAvatar(
                      backgroundImage: NetworkImage(user.photoURL!),
                    ),
            onPressed: () {
              // Navigate to the user's profile screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(userId: user.uid),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(),
    );
  }
}
