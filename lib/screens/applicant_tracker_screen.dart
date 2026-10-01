import 'package:flutter/material.dart';

import 'models/task_model.dart';
import 'services/task_service.dart';

class ApplicantTrackerScreen extends StatelessWidget {
final String taskId;
final TaskService _taskService = TaskService();


ApplicantTrackerScreen({Key? key, required this.taskId}) : super(key:key);


@override
    // TODO: implement createElement
    Widget build(BuildContext context) {

return Scaffold(
  appBar: AppBar(
    title: const Text('Task Applicants'),
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 1,
  ),
  body: StreamBuilder<List<TaskApplicationModel>> (
    stream: _taskService.getTaskApplications(taskId),
    builder: (context, snapshot) {
if(snapshot.connectionState == ConnectionState.waiting) {
  return const Center(child: CircularProgressIndicator());
}
if(!snapshot.hasData || snapshot.data!.isEmpty) {
  return const Center(child: Text('No applications submitted yet.'));
}
final applications = snapshot.data!;

return ListView.builder(
padding: const EdgeInsets.all(16),
itemCount: applications.length,
itemBuilder: (context,index) {
  final app = applications[index];
  return Card (
    margin: const EdgeInsets.only(bottom:12),
    shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child:Padding (
      padding: const EdgeInsets.all(16.0),
      child: Column(
      crossAxisAlignment:CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          child: Text(app.applicantName.substring(0,2).toUpperCase()),
        ),
        const SizedBox(width :12),
        Expanded(
          child:Column(
          crossAxisAlignment:CrossAxisAlignment.start,
          children: [
            Text(app.applicantName,style: const TextStyle(fontWeight: FontWeight.bold)),
            Row (
              children: [
                const Icon(Icons.star, size:14, color: Colors.amber),
                Text('${app.rating} (${app.reviewCount}) reviews)',style: const TextStyle(fontSize:12,color:Colors.grey)),
              ],
              ),
          ],
          ),
        ),
        Chip(
          label: Text(app.status,style:const TextStyle(fontSize:12)),
          backgroundColor:app.status == 'Accepted' ? Colors.green.shade100 : Colors.grey.shade200,
        ),
      ],
      ),

      if(app.pitch.isEmpty)[ 
        const SizedBox(height:12),
        Text(app.pitch, style: TextStyle(color: Colors.grey.shade800, fontSize:13)),
      ],
      const SizedBox(height:12),
    Row (
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton (
          onPressed: () => _taskService.UpdatedApplicationStatus(taskId,app.id!, 'Rejected'),
          child: const Text('Reject', style: TextStyle(color:Colors.red)),
        ),

        const SizedBox(width:8),
        ElevatedButton(
          onPressed: () => _taskService.updatedApplicationSTATUS(TaskId, app.id!, 'Accepted'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
          child: const Text('Accept', style: TextStyle(color:Colors.white)),
        ),
      ],
    ),
      ],
    ),
  ),
),
    },
  ),
    },
    ),
    ),
}
},

          
       




