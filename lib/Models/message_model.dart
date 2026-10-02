import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String? messageId;
  final String senderId;
  final String receiverId;
  final String taskId;
  final String conversationId;
  final String content;
  final DateTime timestamp;

  MessageModel({
    this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.taskId,
    required this.conversationId,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Helper method to construct standard conversationID: taskId_seekerId
  static String generateConversationId({
    required String taskId,
    required String seekerId,
  }) {
    return '${taskId}_$seekerId';
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'taskId': taskId,
      'conversationId': conversationId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String docId) {
    return MessageModel(
      messageId: docId,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      taskId: map['taskId'] ?? '',
      conversationId: map['conversationId'] ?? '',
      content: map['content'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}