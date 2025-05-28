import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyAuthProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;

  MyAuthProvider() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<void> syncWithFirebaseUser(User? user) async {
    _user = user;
    notifyListeners();
  }

  Future<String?> getUserRole(String uid) async {
    if (_user == null) return null;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .get();
    return userDoc.data()?['role'] as String? ?? 'user';
  }

  Future<void> signUp(String email, String password, String name) async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
          'email': email,
          'name': name,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });
        _user = credential.user;
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Signup failed: $e');
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      _user = credential.user;
      notifyListeners();
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> updateUserProfile(String uid, Map<String, String> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update(data);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }
}
