import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class MyAuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  bool _isLoggedIn = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;

  Future<void> setUser(UserModel user) async {
    _user = user;
    _isLoggedIn = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userData', jsonEncode(user.toMap()));
    notifyListeners();
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update(updates);

      // Update local user data
      if (_user != null) {
        _user = _user!.copyWith(
          name: updates['name'] ?? _user!.name,
          profileImageUrl: updates['profileImageUrl'] ?? _user!.profileImageUrl,
        );
        await setUser(_user!);
      }
    } catch (e) {
      if (kDebugMode) print('Error updating user profile: $e');
      rethrow;
    }
  }

  Future<void> syncWithFirebaseUser(User? firebaseUser) async {
    if (firebaseUser == null) {
      await logout();
      return;
    }

    if (_user == null || _user?.uid != firebaseUser.uid) {
      // Check if user exists in Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      UserModel newUser;
      if (doc.exists) {
        newUser = UserModel.fromMap(doc.data()!);
      } else {
        // Create new user if doesn't exist
        newUser = UserModel(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName ?? '',
          email: firebaseUser.email ?? '',
          role: 'user',
          profileImageUrl: firebaseUser.photoURL,
        );
        // Save to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set(newUser.toMap());
      }
      await setUser(newUser);
    }
  }

  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('userData');
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (userData != null) {
        _user = UserModel.fromMap(jsonDecode(userData));
        _isLoggedIn = true;
      } 
      
      if (firebaseUser != null) {
        await syncWithFirebaseUser(firebaseUser);
      }
    } catch (e) {
      if (kDebugMode) print('Error loading user: $e');
      _isLoggedIn = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      _user = null;
      _isLoggedIn = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userData');
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error during logout: $e');
      rethrow;
    }
  }

  getUserRole() {}
}