import 'package:flutter/material.dart';
import '../models/conversation_model.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatelessWidget {
  final String currentUserId;

  const ConversationsScreen({
    super.key,
    required this.currentUserId,
  });

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

          // Group conversations by taskId for organized provider view
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
                  // Task Section Header
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

                  // Individual Applicant / Inquiry Rows
                  ...taskConversations.map((conv) {
                    final bool isProvider = currentUserId == conv.providerId;
                    final String displayTitle =
                        isProvider ? 'Chat with ${conv.seekerName}' : 'Job Provider';

                    return Container(
                      color: Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          child: Text(
                            isProvider
                                ? (conv.seekerName.isNotEmpty
                                    ? conv.seekerName[0].toUpperCase()
                                    : 'A')
                                : 'P',
                          ),
                        ),
                        title: Text(
                          displayTitle,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          conv.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                taskId: conv.taskId,
                                taskTitle: conv.taskTitle,
                                providerId: conv.providerId,
                                seekerId: conv.seekerId,
                                seekerName: conv.seekerName,
                                currentUserId: currentUserId,
                              ),
                            ),
                          );
                        },
                      ),
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