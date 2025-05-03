import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String role;
  final bool openToWork;
  final String? company;     // ← nullable

  UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    required this.openToWork,
    this.company,
  });

  factory UserProfile.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      displayName: data['displayName'],
      email: data['email'],
      role: data['role'],
      openToWork: data['openToWork'] ?? false,
      company: data['company'] as String?,
    );
  }
}
