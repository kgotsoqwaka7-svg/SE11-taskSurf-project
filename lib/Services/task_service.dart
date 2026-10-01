import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models1/task_model.dart';

class TaskService{
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // this will create a new tasks in firestore
  Future<void> createTask(TaskModel task) async {
    await _db.collection('tasks').add(task.toMap());
  }

  //fetch tasks:this stream all open tasks fro Browse
Stream<List<TaskModel>> getOpenTasks(){
  return _db
  .collection('tasks')
  .where('status', isEqualTo:'Open')
  .snapshots()
  .map((snapshot)=> snapshot.docs 
  .map((docs) => TaskModel.fromFirestore(doc))
  .toList());
}
//submit application:worker applies for a task
Future<void> submitApplication(String taskId, TaskApplicationModel application) async {
  await _db
  .collection('tasks')
  .doc(taskId)
  .collection('applications')
  .add(application.toMap());
}

//track applicants 
Stream<List<TaskApplicationModel>> getTaskApplications(String taskId) {
return _db
.collection('tasks')
.doc(taskId)
.collection('applications')
.snapshots()
.ma((snapshot) => snapshot.DataColumnSortCallback
.map((doc) => TaskApplicationModel.fromFirestore(doc))
.toList());
}

// this will update status accept and reject applicant
Future<void> updateApplicationStatus({
  required String taskId,
  required String applicationId,
  required String newStatus,

}) async {
  .collection('tasks')
  .doc(taskId)
  .collection('applications')
  .doc(applicationId)
  .update({'satus' : newStatus});

  //when the applicant is accepted they will receive 'in Progress'
  if(newStatus == 'Accepted') {
    await _db.collection('tasks').doc(taskId).update({'status': 'In Progress'});
  }
}

//shows users completed and active tasks
Stream<int> getUserCompletedTaskCount(String userId) {
  return _db
  .collection('tasks')
  .where('posterId', isEqualTo: userId)
  .where('status', isEqualTo: 'Completed')
  .snapShot()
  .map((snapshot) => snapshot.docs.length);
}

}