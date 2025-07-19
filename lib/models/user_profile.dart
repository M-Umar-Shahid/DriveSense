import 'package:cloud_firestore/cloud_firestore.dart';

/// ─── New helper class for each stint ────────────────────────────────
class Assignment {
  final String companyId;
  final DateTime dateHired;
  final DateTime? dateLeft;
  final String status; // "active" | "inactive" | "fired"

  Assignment({
    required this.companyId,
    required this.dateHired,
    this.dateLeft,
    required this.status,
  });

  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      companyId: map['companyId'] as String,
      dateHired: (map['dateHired'] as Timestamp).toDate(),
      dateLeft:  (map['dateLeft']  as Timestamp?)?.toDate(),
      status:    map['status']    as String,
    );
  }
}

/// ─── Updated UserProfile ────────────────────────────────────────────
class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String role;               // "driver" or "company_admin"
  final bool openToWork;

  /// NEW: full history of companies this user ever worked for
  final List<String> companyHistory;

  /// NEW: timeline of hire/leave events
  final List<Assignment> assignments;

  UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    required this.openToWork,
    this.companyHistory = const [],
    this.assignments    = const [],
  });

  factory UserProfile.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    // Safely cast your new array fields, or default to empty:
    final history = (data['companyHistory'] as List<dynamic>?)
        ?.cast<String>() ?? [];

    final assignsRaw = (data['assignments']    as List<dynamic>?) ?? [];
    final assigns    = assignsRaw
        .map((e) => Assignment.fromMap(e as Map<String, dynamic>))
        .toList();

    return UserProfile(
      uid:            doc.id,
      displayName:    data['displayName'] as String? ?? '',
      email:          data['email']       as String? ?? '',
      role:           data['role']        as String? ?? 'driver',
      openToWork:     data['openToWork']  as bool?   ?? false,
      companyHistory: history,
      assignments:    assigns,
    );
  }

  /// Handy getter for “current” company (or null if none)
  String? get currentCompanyId {
    for (var a in assignments) {
      if (a.status == 'active') return a.companyId;
    }
    return null;
  }
}
