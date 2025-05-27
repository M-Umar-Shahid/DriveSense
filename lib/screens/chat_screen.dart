import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String companyId;
  final String peerId; // Admin: driver's UID, Driver: admin UID

  const ChatScreen({super.key, required this.companyId, required this.peerId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  String _peerName = '';
  String _companyOrRole = '';

  @override
  void initState() {
    super.initState();
    _loadPeerInfo();
  }

  Future<void> _loadPeerInfo() async {
    final userSnap = await FirebaseFirestore.instance.collection('users').doc(widget.peerId).get();
    final userData = userSnap.data();
    if (userData != null) {
      setState(() {
        _peerName = userData['displayName'] ?? 'User';
        _companyOrRole = userData['role'] == 'company_admin'
            ? 'Company: ${userData['company'] ?? ''}'
            : 'Driver';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = currentUser!.uid != widget.peerId;
    final chatDocId = isAdmin ? widget.peerId : currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_peerName, style: const TextStyle(fontSize: 18)),
            Text(_companyOrRole, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('companies')
                  .doc(widget.companyId)
                  .collection('chats')
                  .doc(chatDocId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;

                return ListView(
                  padding: const EdgeInsets.all(10),
                  children: messages.map((doc) {
                    final isMe = doc['senderId'] == currentUser!.uid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blueAccent : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          doc['text'],
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: "Type your message...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
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
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}