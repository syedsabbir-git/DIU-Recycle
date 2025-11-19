import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Get the OneSignal Player ID (also known as device ID or user ID)
  /// Returns the ID as a String, or null if it can't be retrieved
  Future<String?> _getOneSignalPlayerId() async {
    try {
      // Access the user's OneSignal ID directly from the User object
      final playerId = OneSignal.User.pushSubscription.id;

      if (kDebugMode) {
        print('OneSignal Player ID: $playerId');
      }
      return playerId;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting OneSignal Player ID: $e');
      }
      return null;
    }
  }

  Future<User?> createUserWithEmailAndPassword(
    String email,
    String password,
    BuildContext context, {
    required String fullName,
  }) async {
    try {
      // Create the user with email and password
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        // Get the OneSignal player ID
        final oneSignalPlayerId = await _getOneSignalPlayerId();

        // Create a user document in Firestore
        await _firestore.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'email': email,
          'fullName': fullName,
          'profileImageUrl': null,
          'oneSignalPlayerId': oneSignalPlayerId, // Store the OneSignal ID
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Update the user's display name in Firebase Auth
        await cred.user!.updateDisplayName(fullName);

        
      }

      return cred.user;
    } catch (e) {
      if (kDebugMode) {
        print('Create user error: $e');
      }
      rethrow; 
    }
  }

  Future<User?> loginUserWithEmailAndPassword(
    String email,
    String password,
    BuildContext context,
  ) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        // Get the OneSignal player ID
        final oneSignalPlayerId = await _getOneSignalPlayerId();

        // Update last login timestamp and OneSignal ID
        await _firestore.collection('users').doc(cred.user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
          'oneSignalPlayerId':
              oneSignalPlayerId, // Update OneSignal ID on login
        });
      }

      return cred.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendEmailVerification(BuildContext context) async {
    try {
      await _auth.currentUser?.sendEmailVerification();

      // Update email verification status in Firestore
      if (_auth.currentUser != null) {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update({
          'isEmailVerified': true,
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (_auth.currentUser != null) {
        final docSnapshot = await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .get();

        if (docSnapshot.exists) {
          return docSnapshot.data();
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserData(Map<String, dynamic> data) async {
    try {
      if (_auth.currentUser != null) {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update(data);
      }
    } catch (e) {
      rethrow;
    }
  }


  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> sendResetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

 Future<void> signout() async {
  try { 
    await _auth.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
  } catch (e) {
    rethrow;
  }
}

  Future<void> deleteUser() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Delete user data from Firestore first
        await _firestore.collection('users').doc(currentUser.uid).delete();

        await currentUser.delete();

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', false);
      } else {
        throw Exception('No user currently logged in');
      }
    } catch (e) {
      rethrow;
    }
  }
}
