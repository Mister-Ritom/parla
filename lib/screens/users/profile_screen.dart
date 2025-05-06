import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:parla/screens/users/edit_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:parla/auth/auth_provider.dart' as local;

class ProfileScreen extends StatelessWidget {
  final String userId;
  final String currentUserId =
      FirebaseAuth.instance.currentUser?.uid ?? 'no user id';

  ProfileScreen({super.key, required this.userId});

  Future<Map<String, dynamic>?> _getUserData() async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.exists ? doc.data() : null;
  }

  Future<bool> _checkBlocked(String blockerId, String blockedId) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(blockerId)
            .collection('blockedUsers')
            .doc(blockedId)
            .get();
    return snapshot.exists;
  }

  Future<void> _blockUser() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('blockedUsers')
        .doc(userId)
        .set({'blockedAt': FieldValue.serverTimestamp()});
  }

  Future<void> _unblockUser() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('blockedUsers')
        .doc(userId)
        .delete();
  }

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  bool _isCurrentUser() => currentUserId == userId;

  void _showBlockConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dContext) => AlertDialog(
            title: const Text('Block User'),
            content: const Text('Are you sure you want to block this user?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  await _blockUser();
                  if (!dContext.mounted) return;
                  Navigator.pop(dContext);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('User blocked')));
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Block'),
              ),
            ],
          ),
    );
  }

  Widget _buildPopupMenu(BuildContext context, Map<String, dynamic> userData) {
    return PopupMenuButton<String>(
      icon: const Icon(FontAwesomeIcons.ellipsis),
      color: Theme.of(context).colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (value) {
        switch (value) {
          case 'signout':
            _signOut(context);
            break;
          case 'edit':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProfileScreen(userMap: userData),
              ),
            );
            break;
          case 'block':
            _showBlockConfirmationDialog(context);
            break;
        }
      },
      itemBuilder:
          (context) =>
              _isCurrentUser()
                  ? [
                    const PopupMenuItem(
                      value: 'signout',
                      child: Text('Sign Out'),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit Profile'),
                    ),
                  ]
                  : [
                    const PopupMenuItem(value: 'block', child: Text('Block')),
                    const PopupMenuItem(value: 'report', child: Text('Report')),
                  ],
    );
  }

  Widget _buildBlockedWarning(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkBlocked(currentUserId, userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }
        if (snapshot.data == true) {
          return RichText(
            text: TextSpan(
              text: 'You have blocked this user',
              style: const TextStyle(color: Colors.red, fontSize: 16),
              children: [
                TextSpan(
                  text: ' (Tap to unblock)',
                  style: const TextStyle(color: Colors.blue, fontSize: 16),
                  recognizer:
                      TapGestureRecognizer()
                        ..onTap = () async {
                          await _unblockUser();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('User unblocked')),
                            );
                            Navigator.pop(context);
                          }
                        },
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildProfileDetails(Map<String, dynamic> userData, context) {
    return Column(
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
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                const Icon(FontAwesomeIcons.circleCheck, color: Colors.green),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkBlocked(userId, currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data == true) {
          return const Center(
            child: Text('You have been blocked by this user'),
          );
        }
        return FutureBuilder<Map<String, dynamic>?>(
          future: _getUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('User not found'));
            }

            final userData = snapshot.data!;
            return Scaffold(
              appBar: AppBar(
                title: const Text('Profile'),
                actions: [_buildPopupMenu(context, userData)],
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBlockedWarning(context),
                    _buildProfileDetails(userData, context),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
