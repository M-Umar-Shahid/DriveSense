// lib/services/request_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestService {
  final _db = FirebaseFirestore.instance;

  // A) Driver → Company: join request
  Future<void> sendJoinRequest(String companyId) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db.collection('requests').add({
      'type':       'join_company',
      'fromId':     uid,
      'toId':       companyId,
      'timestamp':  FieldValue.serverTimestamp(),
      'status':     'pending',
    });
  }

  // B) Company → Driver: hire request
  Future<void> sendHireRequest(String companyId, String driverId) {
    return _db.collection('requests').add({
      'type':       'hire_driver',
      'fromId':     companyId,
      'toId':       driverId,
      'timestamp':  FieldValue.serverTimestamp(),
      'status':     'pending',
    });
  }

  // C) Accept or reject a request
  Future<void> respondToRequest(String requestId, bool accept) async {
    final reqRef = _db.collection('requests').doc(requestId);
    final reqSnap = await reqRef.get();
    final data   = reqSnap.data()!;
    final type   = data['type'] as String;
    final fromId = data['fromId'] as String;
    final toId   = data['toId'] as String;

    // 1) Update status
    await reqRef.update({'status': accept ? 'accepted' : 'rejected'});

    if (!accept) return;

    // 2) If accepted, do the actual assignment
    if (type == 'hire_driver') {
      // fromId=company, toId=driver
      await _db.collection('companies').doc(fromId).update({
        'driverIds': FieldValue.arrayUnion([toId]),
      });
      await _db.collection('users').doc(toId).update({'company': fromId});
    } else {
      // join_company: fromId=driver, toId=company
      await _db.collection('companies').doc(toId).update({
        'driverIds': FieldValue.arrayUnion([fromId]),
      });
      await _db.collection('users').doc(fromId).update({'company': toId});
    }
  }
}
