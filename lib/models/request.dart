import 'package:cloud_firestore/cloud_firestore.dart';

/// The two types of requests we support.
enum RequestType {
  joinCompany,  // driver → company
  hireDriver,   // company → driver
}

extension RequestTypeExtension on RequestType {
  String get value {
    switch (this) {
      case RequestType.joinCompany:
        return 'join_company';
      case RequestType.hireDriver:
        return 'hire_driver';
    }
  }

  static RequestType fromString(String s) {
    switch (s) {
      case 'hire_driver':
        return RequestType.hireDriver;
      case 'join_company':
      default:
        return RequestType.joinCompany;
    }
  }
}

/// The status of a request.
enum RequestStatus { pending, accepted, rejected }

extension RequestStatusExtension on RequestStatus {
  String get value {
    switch (this) {
      case RequestStatus.pending:
        return 'pending';
      case RequestStatus.accepted:
        return 'accepted';
      case RequestStatus.rejected:
        return 'rejected';
    }
  }

  static RequestStatus fromString(String s) {
    switch (s) {
      case 'accepted':
        return RequestStatus.accepted;
      case 'rejected':
        return RequestStatus.rejected;
      case 'pending':
      default:
        return RequestStatus.pending;
    }
  }
}

/// A wrapper for a Firestore `requests/{id}` document.
class RequestModel {
  final String id;
  final RequestType type;
  final String fromId;
  final String toId;
  final DateTime timestamp;
  final RequestStatus status;

  RequestModel({
    required this.id,
    required this.type,
    required this.fromId,
    required this.toId,
    required this.timestamp,
    required this.status,
  });

  /// Create from a Firestore snapshot
  factory RequestModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data()!;
    return RequestModel(
      id: snap.id,
      type: RequestTypeExtension.fromString(data['type'] as String),
      fromId: data['fromId'] as String,
      toId: data['toId'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: RequestStatusExtension.fromString(data['status'] as String),
    );
  }

  /// Convert to a map suitable for writing to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'type':      type.value,
      'fromId':    fromId,
      'toId':      toId,
      'timestamp': Timestamp.fromDate(timestamp),
      'status':    status.value,
    };
  }
}
