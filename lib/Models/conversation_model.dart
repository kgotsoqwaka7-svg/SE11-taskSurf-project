import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String conversationId;
  final String taskId;
  final String taskTitle;
  final String providerId;
  final String providerName;
  final String seekerId;
  final String seekerName;
  final String lastMessage;
  final DateTime lastUpdated;

  ConversationModel({
    required this.conversationId,
    required this.taskId,
    required this.taskTitle,
    required this.providerId,
    required this.providerName,
    required this.seekerId,
    required this.seekerName,
    required this.lastMessage,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'providerId': providerId,
      'providerName': providerName,
      'seekerId': seekerId,
      'seekerName': seekerName,
      'lastMessage': lastMessage,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'participants': [providerId, seekerId],
    };
  }

  factory ConversationModel.fromMap(Map<String, dynamic> map) {
    return ConversationModel(
      conversationId: map['conversationId'] ?? '',
      taskId: map['taskId'] ?? '',
      taskTitle: map['taskTitle'] ?? '',
      providerId: map['providerId'] ?? '',
      providerName: map['providerName'] ?? '',
      seekerId: map['seekerId'] ?? '',
      seekerName: map['seekerName'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}