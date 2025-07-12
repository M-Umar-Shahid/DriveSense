// lib/services/chat_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class ChatService {
  final _db    = FirebaseFirestore.instance;
  final _notes = NotificationService();

  /// Now chatId should *always* be the driver’s UID
  Future<void> sendMessage({
    required String companyId,
    required String chatId,    // <-- driverId
    required String senderId,
    required String recipientId,
    required String text,
  }) async {
    // 1️⃣  Write the message
    final msgDoc = await _db
        .collection('companies')
        .doc(companyId)
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId' : senderId,
      'text'     : text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2️⃣  Only fire a notification if the message truly went to someone else
    if (recipientId != senderId) {
      await _notes.create(
        toId     : recipientId,
        type     : 'chat',
        message  : '💬 New message from ${senderId.substring(0,6)}',
        refId    : msgDoc.id,
        companyId: companyId,
      );
    }
  }
}
