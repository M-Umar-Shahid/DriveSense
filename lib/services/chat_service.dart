// lib/services/chat_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class ChatService {
  final _db    = FirebaseFirestore.instance;
  final _notes = NotificationService();

  Future<void> sendMessage({
    required String companyId,
    required String chatId,
    required String senderId,
    required String recipientId,
    required String text,
  }) async {
    print('Writing chat message to: '
        '/companies/$companyId/chats/$chatId/messages');

    // 1) Add message under companies/{companyId}/chats/{chatId}/messages
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

    // 2) Fire your in-app notification as before
    await _notes.create(
      toId    : recipientId,
      type    : 'chat',
      message : '💬 New message from ${senderId.substring(0,6)}',
      refId   : msgDoc.id,
      companyId  : companyId,
    );
  }
}
