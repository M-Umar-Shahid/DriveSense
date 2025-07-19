// lib/services/request_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class RequestService {
  final CollectionReference _reqs = FirebaseFirestore.instance.collection('requests');
  final NotificationService _notes = NotificationService();

  Future<bool> hasPendingJoinRequest(String companyId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final pending = await _reqs
        .where('type',   isEqualTo: 'join_company')
        .where('fromId', isEqualTo: uid)
        .where('toId',   isEqualTo: companyId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    return pending.docs.isNotEmpty;
  }

  /// Sends a join‐company request (driver → company).
  /// Returns true if the request was created; false if a pending one already exists.
  Future<bool> sendJoinRequest(String companyId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // 1) Prevent duplicate pending join requests
    final pending = await _reqs
        .where('type',    isEqualTo: 'join_company')
        .where('fromId',  isEqualTo: uid)
        .where('toId',    isEqualTo: companyId)
        .where('status',  isEqualTo: 'pending')
        .limit(1)
        .get();
    if (pending.docs.isNotEmpty) {
      // Already have one
      return false;
    }

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
      toId      : companyId,
      type      : 'joinRequest',
      message   : '🚚 ${uid.substring(0,6)} wants to join your fleet',
      refId     : reqDoc.id,
      companyId : companyId,
    );

    return true;
  }

  /// Sends a hire‐driver request (company → driver).
  /// Returns true if the request was created; false if a pending one already exists.
  Future<bool> sendHireRequest(String companyId, String driverId) async {
    // 1) Prevent duplicate pending hire requests
    final pending = await _reqs
        .where('type',    isEqualTo: 'hire_driver')
        .where('fromId',  isEqualTo: companyId)
        .where('toId',    isEqualTo: driverId)
        .where('status',  isEqualTo: 'pending')
        .limit(1)
        .get();
    if (pending.docs.isNotEmpty) {
      return false;
    }

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
      toId      : driverId,
      type      : 'hireRequest',
      message   : '🏢 $companyId sent you a hire request',
      refId     : reqDoc.id,
      companyId : companyId,
    );

    return true;
  }

  /// Accepts or rejects a pending request.
  /// Updates its status field and notifies the original requester.
  Future<void> respondToRequest(String requestId, bool accept) async {
    final docRef = _reqs.doc(requestId);
    final snap   = await docRef.get();
    if (!snap.exists) return;

    final data   = snap.data() as Map<String, dynamic>;
    final fromId = data['fromId'] as String;      // who sent it
    final toId   = data['toId']   as String;      // who received it
    final type   = data['type']   as String;      // join_company | hire_driver
    final newStatus = accept ? 'accepted' : 'rejected';

    // 1) Update the status on the request doc
    await docRef.update({
      'status'    : newStatus,
      'timestamp' : FieldValue.serverTimestamp(), // mark when response happened
    });

    // 2) Compose a response notification
    String responseType = '${type}Response';
    String message;

    if (type == 'join_company') {
      // original: driver → company, so reply goes back to driver (fromId)
      message = accept
          ? '✅ Company $toId accepted your join request'
          : '❌ Company $toId rejected your join request';
    } else if (type == 'hire_driver') {
      // original: company → driver, so reply goes back to company (fromId)
      message = accept
          ? '✅ Driver $toId accepted your hire request'
          : '❌ Driver $toId rejected your hire request';
    } else {
      message = accept
          ? '✅ Your request was accepted'
          : '❌ Your request was rejected';
    }

    // 3) Send the in-app notification
    await _notes.create(
      toId      : fromId,
      type      : responseType,
      message   : message,
      refId     : requestId,
      companyId : toId,   // the “owner” (company) for grouping
    );
  }
}
