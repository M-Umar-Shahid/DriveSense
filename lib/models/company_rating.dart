import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyRating {
  final String id;
  final String companyId;
  final String userId;
  final double rating;
  final String? comment;
  final DateTime timestamp;

  CompanyRating({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.timestamp,
  });

  factory CompanyRating.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data()!;
    return CompanyRating(
      id:         snap.id,
      companyId:  data['companyId'] as String,
      userId:     data['userId'] as String,
      rating:     (data['rating'] as num).toDouble(),
      comment:    data['comment'] as String?,
      timestamp:  (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'companyId': companyId,
    'userId':    userId,
    'rating':    rating,
    'comment':   comment,
    'timestamp': Timestamp.fromDate(timestamp),
  };
}
