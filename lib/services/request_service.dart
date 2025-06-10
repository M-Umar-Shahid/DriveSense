// lib/services/request_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'company_service.dart';

class RequestService {
  final _db = FirebaseFirestore.instance;
  final _reqs = FirebaseFirestore.instance.collection('requests');

  /// Sends a join‐company request (driver → company).
  /// Returns `true` if created, or `false` if there's already a pending one.
  Future<bool> sendJoinRequest(String companyId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // 0) Don’t let an already‐employed driver send ANY new join requests
    final userSnap = await _db.collection('users').doc(uid).get();
    final currentCompany = (userSnap.data()?['company'] as String?)?.trim();
    if (currentCompany != null && currentCompany.isNotEmpty) {
      // driver is already in a company
      return false;
    }

    // 1) Check for an existing pending join_company request
    final existing = await _db
        .collection('requests')
        .where('type', isEqualTo: 'join_company')
        .where('fromId', isEqualTo: uid)
        .where('toId', isEqualTo: companyId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      // already waiting on this company
      return false;
    }

    // 2) Create new
    await _db.collection('requests').add({
      'type':      'join_company',
      'fromId':    uid,
      'toId':      companyId,
      'timestamp': FieldValue.serverTimestamp(),
      'status':    'pending',
    });
    return true;
  }


  /// Sends a hire‐driver request (company → driver).
  /// Returns `true` if created, or `false` if there's already a pending one.
  Future<bool> sendHireRequest(String companyId, String driverId) async {
    // 1) Check for an existing pending hire_driver request
    final existing = await _reqs
        .where('type', isEqualTo: 'hire_driver')
        .where('fromId', isEqualTo: companyId)
        .where('toId', isEqualTo: driverId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      // already waiting on this driver
      return false;
    }

    // 2) Create new
    await _reqs.add({
      'type':      'hire_driver',
      'fromId':    companyId,
      'toId':      driverId,
      'timestamp': FieldValue.serverTimestamp(),
      'status':    'pending',
    });
    return true;
  }

  Future<void> respondToRequest(String requestId, bool accept) async {
    final reqRef  = _db.collection('requests').doc(requestId);
    final reqSnap = await reqRef.get();
    final data    = reqSnap.data()!;
    final type    = data['type']   as String;
    final fromId  = data['fromId'] as String;
    final toId    = data['toId']   as String;

    // 1) Update the request’s status
    await reqRef.update({'status': accept ? 'accepted' : 'rejected'});
    if (!accept) return;

    // 2) If accepted, do the hire/join via your service
    final cs = CompanyService();
    if (type == 'hire_driver') {
      // company → driver
      await cs.addDriverToCompany(
        companyId: fromId,
        driverId:  toId,
      );
    } else if (type == 'join_company') {
      // driver → company
      await cs.addDriverToCompany(
        companyId: toId,
        driverId:  fromId,
      );
    }
  }
}
