// lib/screens/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/chat_service.dart';
import 'full_screen_image_view.dart';

class ChatScreen extends StatefulWidget {
  final String companyId;
  final String peerId;

  const ChatScreen({
    Key? key,
    required this.companyId,
    required this.peerId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();

  String?   _chatPartnerId;
  String    _peerName       = '';
  String    _peerRole       = '';
  String?   _peerPhotoUrl;
  bool      _loadingPartner = true;
  late bool _iAmDriver;

  @override
  void initState() {
    super.initState();
    _determinePartnerAndLoadInfo();
  }

  Future<void> _determinePartnerAndLoadInfo() async {
    final me = FirebaseAuth.instance.currentUser!;
    final meSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(me.uid)
        .get();
    final meData = meSnap.data()!;
    final myRole = meData['role'] as String? ?? 'driver';
    _iAmDriver = myRole == 'driver';

    String partnerId;

    if (_iAmDriver) {
      // DRIVER: look in your assignments array for the *active* company
      final assigns = (meData['assignments'] as List<dynamic>? ?? []);
      final active = assigns.cast<Map<String, dynamic>>().firstWhere(
            (a) => a['status'] == 'active',
        orElse: () => <String, dynamic>{},
      );
      if (active.isEmpty || active['companyId'] == null) {
        throw Exception("No active assignment found in your profile.");
      }
      final companyId = active['companyId'] as String;

      // fetch that company doc → pick up its adminId
      final compSnap = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .get();
      final compData = compSnap.data()!;
      partnerId = compData['adminId'] as String? ??
          (throw Exception("Company is missing an adminId"));
    } else {
      // ADMIN: peerId is the driver’s UID
      partnerId = widget.peerId;
    }

    // now load their user profile for display
    final peerSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(partnerId)
        .get();
    final peerData = peerSnap.data()!;

    setState(() {
      _chatPartnerId  = partnerId;
      _peerName       = peerData['displayName'] as String? ?? 'Unknown';
      _peerRole       = peerData['role'] == 'company_admin' ? 'Admin' : 'Driver';
      _peerPhotoUrl   = peerData['photoURL'] as String?;
      _loadingPartner = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingPartner) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final meUid   = FirebaseAuth.instance.currentUser!.uid;
    final driverId = _iAmDriver ? meUid : _chatPartnerId!;
    final adminId  = _iAmDriver ? _chatPartnerId! : meUid;
    final chatId   = driverId;        // ★★ ALWAYS use driver’s UID as the doc ID
    final partner  = _chatPartnerId!; // who you’re chatting with

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        leading: const BackButton(color: Colors.white),
        title: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: _peerPhotoUrl != null
                  ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImageView(imageUrl: _peerPhotoUrl!),
                ),
              )
                  : null,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white24,
                backgroundImage:
                _peerPhotoUrl != null ? NetworkImage(_peerPhotoUrl!) : null,
                child: _peerPhotoUrl == null
                    ? Text(
                  _peerName.isNotEmpty ? _peerName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white),
                )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_peerName,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text(_peerRole,
                    style:
                    const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Messages List ────────────────────
            Expanded(
              child: Container(
                color: Colors.grey[50],
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('companies')
                      .doc(widget.companyId)
                      .collection('chats')
                      .doc(chatId)
                      .collection('messages')
                      .orderBy('timestamp')
                      .snapshots(),
                  builder: (ctx, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snap.data!.docs;
                    return ListView.builder(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: docs.length,
                      itemBuilder: (ctx, i) {
                        final msg = docs[i];
                        final isMine = msg['senderId'] == meUid;
                        return Align(
                          alignment: isMine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            constraints: BoxConstraints(
                                maxWidth:
                                MediaQuery.of(context).size.width * 0.75),
                            decoration: BoxDecoration(
                              color:
                              isMine ? Colors.blueAccent : Colors.grey[300],
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(12),
                                topRight: const Radius.circular(12),
                                bottomLeft:
                                Radius.circular(isMine ? 12 : 0),
                                bottomRight:
                                Radius.circular(isMine ? 0 : 12),
                              ),
                            ),
                            child: Text(
                              msg['text'],
                              style: TextStyle(
                                color: isMine ? Colors.white : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // ── Input Bar ─────────────────────────
            Container(
              color: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Type your message…",
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.blueAccent,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () async {
                        final text = _controller.text.trim();
                        if (text.isEmpty) return;
                        await _chatService.sendMessage(
                          companyId: widget.companyId,
                          chatId: chatId,       // driverId
                          senderId: meUid,
                          recipientId: partner, // adminId or driverId
                          text: text,
                        );
                        _controller.clear();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
