import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AdminUserProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _error;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAllUsers() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firestore.collection('users').get();
      _users = snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Error fetching users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({'role': newRole});
      await fetchAllUsers(); // Refresh the list
    } catch (e) {
      if (kDebugMode) print('Error updating user role: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      // First delete from Firestore
      await _firestore.collection('users').doc(userId).delete();
      
      // Then delete from Authentication (requires admin privileges)
      // Note: This requires Firebase Admin SDK or Cloud Function in production
      await fetchAllUsers(); // Refresh the list
    } catch (e) {
      if (kDebugMode) print('Error deleting user: $e');
      rethrow;
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final snapshot = await _firestore.collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '${query}z')
          .get();
      
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    } catch (e) {
      if (kDebugMode) print('Error searching users: $e');
      return [];
    }
  }
}