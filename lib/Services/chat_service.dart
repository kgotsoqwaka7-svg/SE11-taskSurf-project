import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sends a message and updates or creates the conversation metadata entry
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String taskId,
    required String taskTitle,
    required String providerId,
    required String providerName,
    required String seekerId,
    required String seekerName,
    required String content,
  }) async {
    final String conversationId = MessageModel.generateConversationId(
      taskId: taskId,
      seekerId: seekerId,
    );

    final DateTime now = DateTime.now();

    // Create message model
    final message = MessageModel(
      senderId: senderId,
      receiverId: receiverId,
      taskId: taskId,
      conversationId: conversationId,
      content: content.trim(),
      timestamp: now,
    );

    // Add message to the 'messages' subcollection inside conversation
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add(message.toMap());

    // Update top-level conversation metadata for the inbox view
    final conversationSummary = ConversationModel(
      conversationId: conversationId,
      taskId: taskId,
      taskTitle: taskTitle,
      providerId: providerId,
      providerName: providerName,
      seekerId: seekerId,
      seekerName: seekerName,
      lastMessage: content.trim(),
      lastUpdated: now,
    );

    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .set(conversationSummary.toMap(), SetOptions(merge: true));
  }

  /// Streams real-time messages for a specific conversation thread
  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Streams all conversations involving the logged-in user (for the inbox)
  Stream<List<ConversationModel>> getUserConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final conversations = snapshot.docs
          .map((doc) => ConversationModel.fromMap(doc.data()))
          .toList();

      conversations.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

      return conversations;
    });
  }
}