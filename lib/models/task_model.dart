import 'package:cloud_firestore/clous_firestore.dart';

class TaskApplicationModel {

late final String ? id;
late final String applicantId;
late final String applicantName;
late final double rating;
late final int reviewCount;
late final String pitch;
late final String status;
late final DateTime appliedAt;
late final String ?applicantAvatarUrl;



TaskApplicationModel ({
  this.id,
  required this.applicantId,
  required this.applicantName,
  this.applicantAvatarUrl,
  required this.rating,
  required this.reviewCount,
  required this.pitch,
  this.status = 'Pending',
  required this.appliedAt,
  
});

Map<String ,dynamic> toMap() => {
'applicantId': applicantId,
'applicantName':applicantName,
'applicantAvatarUrl': applicantAvatarUrl,
'rating':rating,
'reviewCount':reviewCount,
'pitch':pitch,
'status':status,
'appliedAt': Timestamp.fromData(appliedAt),
};

factory TaskApplicationModel.fromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String,dynamic>;
  return TaskApplicationModel(
    id:doc.id,
    applicantId: data['applicantId'] ?? '',
    
   applicantName: data['applicantName'] ?? 'Anonymous',
   rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
    reviewCount: data['reviewCount'] ?? 0,
     pitch: data['pitch'] ?? '',
      appliedAt:(data['appliedAt'] as Timestamp?)?.toData() ?? DateTime.now()
      );
}

  get Timestamp => null;
}