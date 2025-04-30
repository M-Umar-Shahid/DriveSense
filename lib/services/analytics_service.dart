import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/detection.dart';

class AnalyticsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<List<Detection>> fetchRecentDetections({int limit = 5}) async {
    if (_uid == null) return [];
    final snap = await _db
        .collection('detections')
        .where('uid', isEqualTo: _uid)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((doc) {
      final ts = (doc['timestamp'] as Timestamp).toDate();
      final type = doc['alertType'] ?? 'Unknown';
      String severity;
      if (type == 'Drowsy' || type == 'Distraction') {
        severity = 'High';
      } else if (type == 'Yawning') {
        severity = 'Medium';
      } else {
        severity = 'Low';
      }
      return Detection(type: type, timestamp: ts, severity: severity);
    }).toList();
  }

  Future<List<int>> fetchWeeklyTrends() async {
    if (_uid == null) return List.filled(7, 0);
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final snap = await _db
        .collection('detections')
        .where('uid', isEqualTo: _uid)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
        .get();
    List<int> counts = List.filled(7, 0);
    for (var doc in snap.docs) {
      final ts = (doc['timestamp'] as Timestamp).toDate();
      counts[ts.weekday % 7]++;
    }
    return counts;
  }

  Future<Map<String,int>> fetchMonthlyBreakdown() async {
    if (_uid == null) return {};
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final snap = await _db
        .collection('detections')
        .where('uid', isEqualTo: _uid)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .get();
    Map<String,int> counts = {};
    for (var doc in snap.docs) {
      final type = doc['alertType'] ?? 'Unknown';
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

  Future<Map<String,dynamic>> fetchTotals() async {
    if (_uid == null) return {'totalAlerts': 0, 'totalHours': 0.0, 'recommendation': ''};
    final alertsSnap = await _db.collection('detections').where('uid', isEqualTo: _uid).get();
    final tripsSnap = await _db.collection('trips').where('uid', isEqualTo: _uid).get();
    int totalAlerts = alertsSnap.size;
    double totalHours = 0;
    Map<String,int> typeCount = {};
    for (var doc in tripsSnap.docs) {
      final start = (doc['startTime'] as Timestamp).toDate();
      final end = doc.data().containsKey('endTime') ? (doc['endTime'] as Timestamp).toDate() : null;
      if (end != null) {
        totalHours += end.difference(start).inMinutes / 60.0;
      }
    }
    for (var doc in alertsSnap.docs) {
      final type = doc['alertType'] ?? 'Unknown';
      typeCount[type] = (typeCount[type] ?? 0) + 1;
    }
    final most = typeCount.entries.fold<MapEntry<String,int>>(
        MapEntry('', 0),
            (prev, curr) => curr.value > prev.value ? curr : prev
    );
    String recommendation;
    switch (most.key) {
      case 'Drowsy': recommendation = 'Avoid drowsy driving'; break;
      case 'Yawning': recommendation = 'Stay hydrated and rested'; break;
      case 'Distraction': recommendation = 'Keep focus on the road'; break;
      default: recommendation = 'Keep up the safe driving!';
    }
    return {'totalAlerts': totalAlerts, 'totalHours': totalHours, 'recommendation': recommendation};
  }
}
