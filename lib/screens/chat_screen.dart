import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../models/message_model.dart';

class ChatScreen extends StatefulWidget {
  final String taskId;
  final String taskTitle;
  final String providerId;
  final String providerName;
  final String seekerId;
  final String seekerName;
  final String currentUserId;

  const ChatScreen({
    super.key,
    required this.taskId,
    required this.taskTitle,
    required this.providerId,
    required this.providerName,
    required this.seekerId,
    required this.seekerName,
    required this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late String _conversationId;
  late String _receiverId;
  String _resolvedOtherName = '';

  @override
  void initState() {
    super.initState();
    _conversationId = MessageModel.generateConversationId(
      taskId: widget.taskId,
      seekerId: widget.seekerId,
    );
    _receiverId = (widget.currentUserId == widget.providerId)
        ? widget.seekerId
        : widget.providerId;

    _fetchRealUserName();
  }

  /// Automatically resolves real target name from Firestore if missing/generic
  Future<void> _fetchRealUserName() async {
    final bool isProvider = widget.currentUserId == widget.providerId;
    final String initialName = isProvider ? widget.seekerName : widget.providerName;

    if (initialName.isNotEmpty &&
        initialName != 'Seeker' &&
        initialName != 'Job Provider' &&
        initialName != 'Applicant' &&
        initialName != 'Chat with Seeker') {
      if (mounted) setState(() => _resolvedOtherName = initialName);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(_receiverId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        final name = data['name'] ?? data['fullName'] ?? data['displayName'] ?? data['username'];
        if (name != null && name.toString().trim().isNotEmpty) {
          if (mounted) setState(() => _resolvedOtherName = name.toString().trim());
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _resolvedOtherName = isProvider ? 'Applicant' : 'Job Provider';
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    await _chatService.sendMessage(
      senderId: widget.currentUserId,
      receiverId: _receiverId,
      taskId: widget.taskId,
      taskTitle: widget.taskTitle,
      providerId: widget.providerId,
      providerName: widget.providerName,
      seekerId: widget.seekerId,
      seekerName: widget.seekerName,
      content: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF1976D2);
    final bool isProvider = widget.currentUserId == widget.providerId;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        backgroundColor: themeColor,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.taskTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              isProvider
                  ? 'Applicant: ${_resolvedOtherName.isNotEmpty ? _resolvedOtherName : widget.seekerName}'
                  : 'Provider: ${_resolvedOtherName.isNotEmpty ? _resolvedOtherName : widget.providerName}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessages(_conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: themeColor),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet. Send an inquiry!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == widget.currentUserId;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14.0,
                          vertical: 10.0,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? themeColor : Colors.white,
                          border: isMe
                              ? null
                              : Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: isMe
                                ? const Radius.circular(12)
                                : Radius.zero,
                            bottomRight: isMe
                                ? Radius.zero
                                : const Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          message.content,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFFF5F9FF),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: themeColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: themeColor,
                    onPressed: _sendMessage,
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