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

    // 2️⃣  Only create a notification if they're not talking to themselves
    if (recipientId == senderId) return;

    // 3️⃣  Look up the sender's name
    String senderName = senderId.substring(0,6); // fallback

    // Try the users collection first
    final userSnap = await _db.collection('users').doc(senderId).get();
    if (userSnap.exists) {
      final data = userSnap.data()!;
      if (data.containsKey('displayName')) {
        senderName = data['displayName'] as String;
      }
    } else {
      // If not a user, try the companies collection
      final compSnap = await _db.collection('companies').doc(senderId).get();
      if (compSnap.exists) {
        final data = compSnap.data()!;
        if (data.containsKey('companyName')) {
          senderName = data['companyName'] as String;
        }
      }
    }

    // 4️⃣  Fire the notification with the real name
    await _notes.create(
      toId     : recipientId,
      type     : 'chat',
      message  : '💬 New message from $senderName',
      refId    : msgDoc.id,
      companyId: companyId,
    );
  }
}
