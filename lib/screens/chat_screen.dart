import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'full_screen_image_view.dart'; // if you ever want to tap avatar
import 'chat_screen.dart';

class ChatScreen extends StatefulWidget {
  final String companyId;
  final String peerId;

  const ChatScreen({Key? key, required this.companyId, required this.peerId})
      : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  String _peerName = '';
  String _peerRole = '';
  String? _peerPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadPeerInfo();
  }

  Future<void> _loadPeerInfo() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.peerId)
        .get();
    final data = snap.data();
    if (data != null) {
      setState(() {
        _peerName = data['displayName'] ?? 'User';
        _peerRole = data['role'] == 'company_admin' ? 'Admin' : 'Driver';
        _peerPhotoUrl = data['photoURL'] as String?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMe = currentUser!.uid != widget.peerId;
    final chatDocId = isMe ? widget.peerId : currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        elevation: 2,
        leading: BackButton(color: Colors.white),
        title: Row(
          children: [
            // Avatar
            InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: _peerPhotoUrl != null
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FullScreenImageView(imageUrl: _peerPhotoUrl!),
                  ),
                );
              }
                  : null,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white24,
                backgroundImage: _peerPhotoUrl != null
                    ? NetworkImage(_peerPhotoUrl!)
                    : null,
                child: _peerPhotoUrl == null
                    ? Text(
                  _peerName.isNotEmpty
                      ? _peerName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white),
                )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            // Name & Role
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _peerName,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  _peerRole,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            // ── Messages ────────────────────────────
            Expanded(
              child: Container(
                color: Colors.grey[50],
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('companies')
                      .doc(widget.companyId)
                      .collection('chats')
                      .doc(chatDocId)
                      .collection('messages')
                      .orderBy('timestamp')
                      .snapshots(),
                  builder: (ctx, snap) {
                    if (!snap.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    final docs = snap.data!.docs;
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: docs.length,
                      itemBuilder: (ctx, i) {
                        final msg = docs[i];
                        final isMine =
                            msg['senderId'] == currentUser!.uid;
                        return Align(
                          alignment: isMine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            constraints:
                            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            decoration: BoxDecoration(
                              color: isMine
                                  ? Colors.blueAccent
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(12),
                                topRight: const Radius.circular(12),
                                bottomLeft: Radius.circular(
                                    isMine ? 12 : 0),
                                bottomRight: Radius.circular(
                                    isMine ? 0 : 12),
                              ),
                            ),
                            child: Text(
                              msg['text'],
                              style: TextStyle(
                                color: isMine
                                    ? Colors.white
                                    : Colors.black87,
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

            // ── Input Bar ───────────────────────────
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
                        hintText: "Type your message...",
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
                        await FirebaseFirestore.instance
                            .collection('companies')
                            .doc(widget.companyId)
                            .collection('chats')
                            .doc(chatDocId)
                            .collection('messages')
                            .add({
                          'text': text,
                          'senderId': currentUser!.uid,
                          'timestamp': FieldValue.serverTimestamp(),
                        });
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
