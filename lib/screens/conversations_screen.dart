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
    final ChatService chatService = ChatService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: StreamBuilder<List<ConversationModel>>(
        stream: chatService.getUserConversations(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No active conversations yet.'),
            );
          }

          final conversations = snapshot.data!;

          // Group conversations by taskId for organized provider view
          final Map<String, List<ConversationModel>> groupedConversations = {};
          for (var conv in conversations) {
            groupedConversations.putIfAbsent(conv.taskId, () => []).add(conv);
          }

          return ListView.builder(
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
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withOpacity(0.4),
                    child: Text(
                      'Task: $taskTitle',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),

                  // Individual Applicant / Inquiry Rows
                  ...taskConversations.map((conv) {
                    final bool isProvider = currentUserId == conv.providerId;
                    final String displayTitle =
                        isProvider ? 'Chat with ${conv.seekerName}' : 'Job Provider';

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          isProvider
                              ? (conv.seekerName.isNotEmpty
                                  ? conv.seekerName[0].toUpperCase()
                                  : 'A')
                              : 'P',
                        ),
                      ),
                      title: Text(displayTitle),
                      subtitle: Text(
                        conv.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
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
                    );
                  }),
                  const Divider(height: 1),
                ],
              );
            },
          );
        },
      ),
    );
  }
}