import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/conversation_model.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatelessWidget {
  final String currentUserId;

  const ConversationsScreen({
    super.key,
    required this.currentUserId,
  });

  /// Fetches the real user name from the 'Users' collection if generic or empty
  Future<String> _resolveUserName({
    required String targetUserId,
    required String rawName,
    required bool isProviderView,
  }) async {
    final cleanName = rawName.trim();
    
    // Ignore generic placeholder strings
    final isGeneric = cleanName.isEmpty ||
        cleanName == 'Seeker' ||
        cleanName == 'Job Provider' ||
        cleanName == 'Applicant' ||
        cleanName == 'Chat with Seeker';

    if (!isGeneric) {
      return cleanName;
    }

    try {
      // 1. Try direct Document ID lookup in 'Users' collection
      var userDoc = await FirebaseFirestore.instance
          .collection('Users') // Capital 'Users' as shown in your Firestore Console
          .doc(targetUserId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        final name = data['name'] ?? data['fullName'] ?? data['displayName'];
        if (name != null && name.toString().trim().isNotEmpty) {
          return name.toString().trim();
        }
      }

      // 2. Query by 'userID' field if doc ID differs
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('userID', isEqualTo: targetUserId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        final name = data['name'] ?? data['fullName'] ?? data['displayName'];
        if (name != null && name.toString().trim().isNotEmpty) {
          return name.toString().trim();
        }
      }
    } catch (_) {}

    return isProviderView ? 'Applicant' : 'Job Provider';
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF1976D2);
    final ChatService chatService = ChatService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        backgroundColor: themeColor,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<ConversationModel>>(
        stream: chatService.getUserConversations(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: themeColor),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No active conversations yet.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final conversations = snapshot.data!;

          final Map<String, List<ConversationModel>> groupedConversations = {};
          for (var conv in conversations) {
            groupedConversations.putIfAbsent(conv.taskId, () => []).add(conv);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: groupedConversations.keys.length,
            itemBuilder: (context, index) {
              final taskId = groupedConversations.keys.elementAt(index);
              final taskConversations = groupedConversations[taskId]!;
              final taskTitle = taskConversations.first.taskTitle;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    color: themeColor.withOpacity(0.1),
                    child: Text(
                      'Task: $taskTitle',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                  ),
                  ...taskConversations.map((conv) {
                    final bool isProvider = currentUserId == conv.providerId;
                    final String otherUserId =
                        isProvider ? conv.seekerId : conv.providerId;
                    final String rawName =
                        isProvider ? conv.seekerName : conv.providerName;

                    return FutureBuilder<String>(
                      future: _resolveUserName(
                        targetUserId: otherUserId,
                        rawName: rawName,
                        isProviderView: isProvider,
                      ),
                      builder: (context, nameSnapshot) {
                        final displayName = nameSnapshot.data ??
                            (isProvider ? 'Applicant' : 'Job Provider');
                        final initial = displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?';

                        return Container(
                          color: Colors.white,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: themeColor,
                              foregroundColor: Colors.white,
                              child: Text(initial),
                            ),
                            title: Text(
                              displayName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              conv.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            trailing:
                                const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    taskId: conv.taskId,
                                    taskTitle: conv.taskTitle,
                                    providerId: conv.providerId,
                                    providerName: conv.providerName,
                                    seekerId: conv.seekerId,
                                    seekerName: conv.seekerName,
                                    currentUserId: currentUserId,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  }),
                  Divider(height: 1, color: Colors.grey.shade300),
                ],
              );
            },
          );
        },
      ),
    );
  }
}