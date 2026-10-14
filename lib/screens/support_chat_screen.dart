import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({
    required this.ticketId,
    required this.subject,
    required this.initialMessage,
    required this.isAdmin,
    required this.isResolved,
    this.userEmail = '',
    this.submittedAt,
    super.key,
  });

  final String ticketId;
  final String subject;
  final String initialMessage;
  final bool isAdmin;
  final bool isResolved;
  final String userEmail;
  final Timestamp? submittedAt;

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  static const Color _blue = Color(0xFF1976D2);
  final _messageController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance
          .collection('supportTickets')
          .doc(widget.ticketId)
          .collection('messages')
          .add({
        'text': text,
        'senderId': user?.uid ?? '',
        'senderRole': widget.isAdmin ? 'admin' : 'user',
        'senderName': widget.isAdmin
            ? 'TaskSurf Support'
            : (user?.email ?? 'You'),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      _messageController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to send message: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketRef = FirebaseFirestore.instance
        .collection('supportTickets')
        .doc(widget.ticketId);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.subject, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              widget.isAdmin
                  ? (widget.userEmail.isEmpty ? 'Support ticket' : widget.userEmail)
                  : 'TaskSurf Support',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: ticketRef
                  .collection('messages')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Unable to load messages: ${snapshot.error}'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data?.docs.toList() ?? [];
                messages.sort((a, b) {
                  final aTime = a.data()['createdAt'];
                  final bTime = b.data()['createdAt'];
                  if (aTime is Timestamp && bTime is Timestamp) {
                    return aTime.compareTo(bTime);
                  }
                  if (aTime is Timestamp) return -1;
                  if (bTime is Timestamp) return 1;
                  return 0;
                });

                final entries = <_ChatEntry>[
                  if (widget.initialMessage.isNotEmpty)
                    _ChatEntry(
                      text: widget.initialMessage,
                      senderRole: 'user',
                      senderName: widget.userEmail.isEmpty
                          ? 'You'
                          : widget.userEmail,
                      createdAt: widget.submittedAt,
                    ),
                  ...messages.map((message) {
                    final data = message.data();
                    return _ChatEntry(
                      text: data['text'] as String? ?? '',
                      senderRole: data['senderRole'] as String? ?? 'user',
                      senderName: data['senderName'] as String? ?? '',
                      createdAt: data['createdAt'] is Timestamp
                          ? data['createdAt'] as Timestamp
                          : null,
                    );
                  }),
                ];

                if (entries.isEmpty) {
                  return const Center(child: Text('Send a message to get started.'));
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[entries.length - 1 - index];
                    final isMine = entry.senderRole ==
                        (widget.isAdmin ? 'admin' : 'user');
                    return _MessageBubble(
                      entry: entry,
                      isMine: isMine,
                    );
                  },
                );
              },
            ),
          ),
          if (widget.isResolved)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: const Text(
                'This ticket has been resolved.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Write a message...',
                          filled: true,
                          fillColor: const Color(0xFFF2F5F9),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _sending ? null : _sendMessage,
                      style: IconButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                      ),
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChatEntry {
  const _ChatEntry({
    required this.text,
    required this.senderRole,
    required this.senderName,
    required this.createdAt,
  });

  final String text;
  final String senderRole;
  final String senderName;
  final Timestamp? createdAt;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.entry, required this.isMine});

  final _ChatEntry entry;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final time = entry.createdAt?.toDate();
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? const Color(0xFF1976D2) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  entry.senderName,
                  style: const TextStyle(
                    color: Color(0xFF1976D2),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Text(
              entry.text,
              style: TextStyle(
                color: isMine ? Colors.white : const Color(0xFF202124),
                height: 1.35,
              ),
            ),
            if (time != null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: isMine ? Colors.white70 : Colors.grey.shade500,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}