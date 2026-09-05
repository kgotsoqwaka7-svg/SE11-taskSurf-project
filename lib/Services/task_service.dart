import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/task_model.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createTask(TaskModel task) async{
    try{
      //The taskID will be used as a document ID in the firestore to make retriving the data easier
      await _firestore.collection('Tasks').doc(task.taskID).set(task.toMap());
    } catch(e){
      print('Error creating task');
      throw e;
    }
  }
}