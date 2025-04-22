import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  User? _currentUser;
  User? get currentUser => _currentUser;
  User get nonNullUser {
    assert(_currentUser != null, 'User is null');
    return _currentUser!;
  }

  AuthProvider() {
    _currentUser = _firebaseAuth.currentUser;
    _firebaseAuth.authStateChanges().listen((User? user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack, label: 'Error signing in');
      rethrow;
    }
  }

  Future<void> registerWithEmailAndPassword(
    String email,
    String password,
    Map<String, dynamic> userData,
  ) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCredential.user?.updateProfile(displayName: userData['name']);
      _currentUser?.reload();
      // save the userdata in users/{userId}/ in firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser?.uid)
          .set(userData);
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack, label: 'Error registering user');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack, label: 'Error signing out');
      rethrow;
    }
  }
}
