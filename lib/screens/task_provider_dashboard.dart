import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'view-applicantions_screen.dart';
import 'post_task_screen.dart';

class TaskProviderDashboard extends StatelessWidget {
  const TaskProviderDashboard({super.key});

  void _deleteTask(BuildContext context, String taskId, String title) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "$title"? This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, elevation: 0),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await FirebaseFirestore.instance.collection('Tasks').doc(taskId).delete();
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting task: $e')));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _markTaskComplete(BuildContext context, String taskId) async {
    try {
      await FirebaseFirestore.instance.collection('Tasks').doc(taskId).update({'status': 'Completed'});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task marked as completed!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        title: const Text('My Posted Tasks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: currentUser == null
          ? const Center(child: Text('Please log in to view your tasks.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Tasks').where('creatorID', isEqualTo: currentUser.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return const Center(child: Text('Error loading tasks.'));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('You have not posted any tasks yet.', style: TextStyle(fontSize: 16)));

                final liveTasks = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(20.0),
                  itemCount: liveTasks.length,
                  itemBuilder: (context, index) {
                    final doc = liveTasks[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final taskId = doc.id;
                    final title = data['title'] ?? 'Untitled Task';
                    final location = data['location'] ?? 'No Location Provided';
                    final status = data['status'] ?? 'Active';
                    final isCompleted = status == 'Completed';

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ViewApplicationsScreen(taskId: taskId)));
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(17),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, 5))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(14)),
                              child: const Icon(Icons.work_outline_rounded, color: Color(0xFF1976D2)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 5),
                                  
                                  // NEW LIVE APPLICANT COUNTER
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance.collection('applications').where('taskId', isEqualTo: taskId).snapshots(),
                                    builder: (context, appSnapshot) {
                                      final count = appSnapshot.hasData ? appSnapshot.data!.docs.length : 0;
                                      return Text('$count applications • $location', style: TextStyle(color: Colors.grey.shade600, fontSize: 12));
                                    }
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        width: 7, height: 7,
                                        decoration: BoxDecoration(color: isCompleted ? Colors.grey : Colors.green, shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(status, style: TextStyle(color: isCompleted ? Colors.grey : Colors.green, fontSize: 11, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                              onSelected: (value) {
                                if (value == 'edit') {
                                 Navigator.push(context, MaterialPageRoute(builder: (context) => PostTaskScreen(taskId: taskId, existingData: data)));
                                } else if (value == 'delete') {
                                  _deleteTask(context, taskId, title);
                                } else if (value == 'complete') {
                                  _markTaskComplete(context, taskId);
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                if (!isCompleted)
                                  const PopupMenuItem(
                                    value: 'complete',
                                    child: Row(children: [Icon(Icons.check_circle_outline, size: 20, color: Colors.green), SizedBox(width: 10), Text('Mark Complete')]),
                                  ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(children: [Icon(Icons.edit_outlined, size: 20, color: Color(0xFF1976D2)), SizedBox(width: 10), Text('Edit Task')]),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(children: [Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red), SizedBox(width: 10), Text('Delete Task', style: TextStyle(color: Colors.red))]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1976D2),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PostTaskScreen())),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Post Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}