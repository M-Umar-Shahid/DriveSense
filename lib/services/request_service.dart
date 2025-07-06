// lib/services/request_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'company_service.dart';
import 'notification_service.dart';

class RequestService {
  final _db    = FirebaseFirestore.instance;
  final _reqs  = FirebaseFirestore.instance.collection('requests');
  final _notes = NotificationService();

  /// Sends a join‐company request (driver → company).
  Future<bool> sendJoinRequest(String companyId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // … your existing checks …

    // 2) Create new join request
    final reqDoc = await _reqs.add({
      'type'      : 'join_company',
      'fromId'    : uid,
      'toId'      : companyId,
      'timestamp' : FieldValue.serverTimestamp(),
      'status'    : 'pending',
    });

    // 3) Notify the company
    await _notes.create(
      toId    : companyId,
      type    : 'joinRequest',
      message : '🚚 ${uid.substring(0,6)} wants to join your fleet',
      refId   : reqDoc.id,
    );

    return true;
  }

  /// Sends a hire‐driver request (company → driver).
  Future<bool> sendHireRequest(String companyId, String driverId) async {
    // … your existing “pending” check …

    // 2) Create new hire request
    final reqDoc = await _reqs.add({
      'type'      : 'hire_driver',
      'fromId'    : companyId,
      'toId'      : driverId,
      'timestamp' : FieldValue.serverTimestamp(),
      'status'    : 'pending',
    });

    // 3) Notify the driver
    await _notes.create(
      toId    : driverId,
      type    : 'hireRequest',
      message : '🏢 $companyId sent you a hire request',
      refId   : reqDoc.id,
    );

    return true;
  }

  Future<void> respondToRequest(String requestId, bool accept) async {
    // … your existing accept/reject logic …

    // Optionally notify the requester that you’ve replied:
    if (accept) {
      final reqSnap = await _db.collection('requests').doc(requestId).get();
      final data    = reqSnap.data()!;
      final fromId  = data['fromId'] as String;
      final toId    = data['toId']   as String;
      final type    = data['type']   as String;

      await _notes.create(
        toId: fromId,
        type: '${type}Response',
        message: accept
            ? (type=='join_company'
            ? '✅ Company $toId accepted your join request'
            : '✅ Driver $toId accepted your hire request')
            : (type=='join_company'
            ? '❌ Company $toId rejected your join request'
            : '❌ Driver $toId rejected your hire request'),
        refId: requestId,
      );
    }
  }
}
