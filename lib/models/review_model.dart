class ReviewModel {
  final String reviewId;
  final String taskId;
  final String reviewerId;
  final String reviewedUserId;
  final double rating;
  final String comment;
  final List<String> tags;
  final bool recommend;
  final DateTime? createdAt;

  ReviewModel({
    required this.reviewId,
    required this.taskId,
    required this.reviewerId,
    required this.reviewedUserId,
    required this.rating,
    required this.comment,
    required this.tags,
    required this.recommend,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> data) {
    return ReviewModel(
      reviewId: data['reviewId']?.toString() ?? '',
      taskId: data['taskId']?.toString() ?? '',
      reviewerId: data['reviewerId']?.toString() ?? '',
      reviewedUserId: data['reviewedUserId']?.toString() ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment']?.toString() ?? '',
      tags: data['tags'] != null
          ? List<String>.from(data['tags'])
          : [],
      recommend: data['recommend'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'taskId': taskId,
      'reviewerId': reviewerId,
      'reviewedUserId': reviewedUserId,
      'rating': rating,
      'comment': comment,
      'tags': tags,
      'recommend': recommend,
      'createdAt': createdAt,
    };
  }
}