// lib/services/chat_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class ChatService {
  final _db    = FirebaseFirestore.instance;
  final _notes = NotificationService();

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String recipientId,
    required String text,
  }) async {
    // 1) Add message to subcollection
    final msgDoc = await _db
        .collection('chats').doc(chatId)
        .collection('messages').add({
      'senderId' : senderId,
      'text'     : text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2) Fire an in-app notification
    await _notes.create(
      toId    : recipientId,
      type    : 'chat',
      message : '💬 New message from ${senderId.substring(0,6)}',
      refId   : msgDoc.id,
    );
  }
}
