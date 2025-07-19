// lib/services/notification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final _db = FirebaseFirestore.instance;
  final _notifs = FirebaseFirestore.instance.collection('notifications');

  /// Creates a notification for `toId`.
  Future<void> create({
    required String toId,
    required String type,
    required String message,
    String? refId,
    required String companyId,
  }) {
    return _notifs.add({
      'to'       : toId,
      'type'     : type,
      'message'  : message,
      'refId'    : refId ?? '',
      'companyId' : companyId,
      'isRead'   : false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
