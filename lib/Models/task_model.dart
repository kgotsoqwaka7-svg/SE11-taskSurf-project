class TaskModel {
  final String taskID;
  final String creatorID;
  final String title;
  final String description;
  final String location;
  final String status;
  final double paymentAmount;
  final int numOfWorkers;
  final String category;
  final String date; // Added date
  final String time; // Added time

  TaskModel({
    required this.taskID,
    required this.creatorID,
    required this.title,
    required this.description,
    required this.location,
    required this.status,
    required this.paymentAmount,
    required this.numOfWorkers,
    required this.category,
    required this.date, // Added date
    required this.time, // Added time
  });

  Map<String, dynamic> toMap() {
    return {
      'taskID': taskID,
      'creatorID': creatorID,
      'title': title,
      'description': description,
      'location': location,
      'status': status,
      'paymentAmount': paymentAmount,
      'numOfWorkers': numOfWorkers,
      'category': category,
      'date': date, // Added date
      'time': time, // Added time
    };
  }
}