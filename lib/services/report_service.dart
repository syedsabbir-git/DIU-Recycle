import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diurecycle/models/report_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Submit a report for a product listing
  Future<bool> reportProduct({
    required String productId,
    required String productOwnerId,
    required String productOwnerName,
    required String reason,
    required String description,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (kDebugMode) {
          print('Error: User not logged in');
        }
        return false;
      }

      // Get reporter information
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final userName = userDoc.data()?['name'] ?? 'Unknown User';

      final reportId = _firestore.collection('reports').doc().id;

      final report = Report(
        id: reportId,
        reporterId: currentUser.uid,
        reporterName: userName,
        reporterEmail: currentUser.email ?? '',
        reportedItemId: productId,
        reportedItemType: 'product',
        reportedUserId: productOwnerId,
        reportedUserName: productOwnerName,
        reason: reason,
        description: description,
        timestamp: DateTime.now(),
        status: 'pending',
      );

      await _firestore.collection('reports').doc(reportId).set(report.toMap());

      if (kDebugMode) {
        print('Product report submitted successfully: $reportId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting product report: $e');
      }
      return false;
    }
  }

  /// Submit a report for a user
  Future<bool> reportUser({
    required String userId,
    required String userName,
    required String reason,
    required String description,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (kDebugMode) {
          print('Error: User not logged in');
        }
        return false;
      }

      // Get reporter information
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final reporterName = userDoc.data()?['name'] ?? 'Unknown User';

      final reportId = _firestore.collection('reports').doc().id;

      final report = Report(
        id: reportId,
        reporterId: currentUser.uid,
        reporterName: reporterName,
        reporterEmail: currentUser.email ?? '',
        reportedItemId: userId,
        reportedItemType: 'user',
        reportedUserId: userId,
        reportedUserName: userName,
        reason: reason,
        description: description,
        timestamp: DateTime.now(),
        status: 'pending',
      );

      await _firestore.collection('reports').doc(reportId).set(report.toMap());

      if (kDebugMode) {
        print('User report submitted successfully: $reportId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting user report: $e');
      }
      return false;
    }
  }

  /// Check if user has already reported an item
  Future<bool> hasUserReported({
    required String itemId,
    required String itemType,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final querySnapshot = await _firestore
          .collection('reports')
          .where('reporterId', isEqualTo: currentUser.uid)
          .where('reportedItemId', isEqualTo: itemId)
          .where('reportedItemType', isEqualTo: itemType)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking if user reported: $e');
      }
      return false;
    }
  }

  /// Get all reports (for admin/moderator use)
  Stream<List<Report>> getAllReports() {
    return _firestore
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Report.fromMap(doc.data()))
            .toList());
  }

  /// Get pending reports count
  Future<int> getPendingReportsCount() async {
    try {
      final querySnapshot = await _firestore
          .collection('reports')
          .where('status', isEqualTo: 'pending')
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting pending reports count: $e');
      }
      return 0;
    }
  }

  /// Update report status (for admin/moderator use)
  Future<bool> updateReportStatus(String reportId, String status) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'status': status,
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating report status: $e');
      }
      return false;
    }
  }
}
