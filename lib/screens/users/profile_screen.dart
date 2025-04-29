import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:parla/screens/users/edit_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:parla/auth/auth_provider.dart' as local;

class ProfileScreen extends StatelessWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  Future<Map<String, dynamic>?> _getUserData() async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.exists ? doc.data() : null;
  }

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading profile'));
        } else if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('User not found'));
        }

        final userData = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(FontAwesomeIcons.ellipsis),
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),

                onSelected: (value) {
                  if (value == 'signout') {
                    _signOut(context);
                  }
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => EditProfileScreen(userMap: userData),
                      ),
                    );
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'signout',
                        child: Text('Sign Out'),
                      ),
                      const PopupMenuItem(
                        value: 'settings',
                        child: Text('Settings'),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit Profile'),
                      ),
                    ],
              ),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (userData['photoUrl'] != null)
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(userData['photoUrl']),
                  ),
                const SizedBox(height: 16),
                Text(
                  userData['name'] ?? 'No Name',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  userData['username'] ?? 'no username',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  userData['email'] ?? 'no email',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Provider.of<local.AuthProvider>(
                      context,
                      listen: false,
                    ).nonNullUser.emailVerified
                    ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          FontAwesomeIcons.circleCheck,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        const Text('Email Verified'),
                      ],
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          FontAwesomeIcons.circleExclamation,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            const Text('Email Not Verified'),
                            TextButton(
                              onPressed: () async {
                                Provider.of<local.AuthProvider>(
                                  context,
                                  listen: false,
                                ).nonNullUser.sendEmailVerification();
                              },
                              child: const Text('Resend Verification Email'),
                            ),
                          ],
                        ),
                      ],
                    ),
                const SizedBox(height: 8),
                Text(userId),
              ],
            ),
          ),
        );
      },
    );
  }
}
