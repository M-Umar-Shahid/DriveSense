import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/detection.dart';

class AnalyticsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetch the most recent [limit] detections for [driverId].
  Future<List<Detection>> fetchRecentDetections(
      String driverId, {
        int limit = 5,
      }) async {
    final snap = await _db
        .collection('detections')
        .where('uid', isEqualTo: driverId)
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

  /// Returns a 7-element list of alert counts for each day of the week,
  /// starting Sunday = index 0.
  Future<List<int>> fetchWeeklyTrends(String driverId) async {
    final now = DateTime.now();
    // Start from the most recent Sunday:
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final snap = await _db
        .collection('detections')
        .where('uid', isEqualTo: driverId)
        .where(
      'timestamp',
      isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek),
    )
        .get();

    List<int> counts = List.filled(7, 0);
    for (var doc in snap.docs) {
      final ts = (doc['timestamp'] as Timestamp).toDate();
      counts[ts.weekday % 7]++;
    }
    return counts;
  }

  Future<Map<String,int>> fetchMonthlyBreakdownForMonth(
      String driverId, DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final startOfNext =
    DateTime(month.year, month.month + 1, 1);
    final snap = await _db
        .collection('detections')
        .where('uid', isEqualTo: driverId)
        .where('timestamp',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('timestamp',
        isLessThan: Timestamp.fromDate(startOfNext))
        .get();

    final counts = <String,int>{};
    for (var doc in snap.docs) {
      final type = doc['alertType'] as String? ?? 'Unknown';
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

  /// Computes totalAlerts, totalHours driven, and a recommendation string.
  Future<Map<String, dynamic>> fetchTotals(String driverId) async {
    // 1) All alerts
    final alertsSnap = await _db
        .collection('detections')
        .where('uid', isEqualTo: driverId)
        .get();

    // 2) All trips (for hours)
    final tripsSnap = await _db
        .collection('trips')
        .where('uid', isEqualTo: driverId)
        .get();

    final int totalAlerts = alertsSnap.size;

    double totalHours = 0;
    for (var doc in tripsSnap.docs) {
      final data = doc.data();
      final start = (data['startTime'] as Timestamp).toDate();
      final end = data.containsKey('endTime')
          ? (data['endTime'] as Timestamp).toDate()
          : null;
      if (end != null) {
        totalHours += end.difference(start).inMinutes / 60.0;
      }
    }

    // 3) Most frequent alert type
    final Map<String, int> typeCount = {};
    for (var doc in alertsSnap.docs) {
      final type = doc['alertType'] ?? 'Unknown';
      typeCount[type] = (typeCount[type] ?? 0) + 1;
    }
    final most = typeCount.entries.fold<MapEntry<String, int>>(
      const MapEntry('', 0),
          (prev, curr) => curr.value > prev.value ? curr : prev,
    );

    String recommendation;
    switch (most.key) {
      case 'Drowsy':
        recommendation = 'Avoid drowsy driving';
        break;
      case 'Yawning':
        recommendation = 'Stay hydrated and rested';
        break;
      case 'Distraction':
        recommendation = 'Keep focus on the road';
        break;
      default:
        recommendation = 'Keep up the safe driving!';
    }

    return {
      'totalAlerts': totalAlerts,
      'totalHours': totalHours,
      'recommendation': recommendation,
    };
  }

  /// Returns a list of 24 ints, one per hour of “alerts in that hour.”
  Future<List<int>> fetchHourlyCounts(String driverId) async {
    final now = DateTime.now();
    final snap = await _db
        .collection('detections')
<<<<<<< Updated upstream
        .where('driverId', isEqualTo: driverId)
=======
<<<<<<< HEAD
        .where('uid', isEqualTo: driverId)
=======
        .where('driverId', isEqualTo: driverId)
>>>>>>> 16548fd9f372664a8405d77e23307aa5fba1743b
>>>>>>> Stashed changes
        .where('timestamp', isGreaterThan: Timestamp.fromDate(now.subtract(Duration(hours: 24))))
        .get();

    final buckets = List<int>.filled(24, 0);
    for (var doc in snap.docs) {
      final dt = (doc['timestamp'] as Timestamp).toDate();
      buckets[dt.hour]++;
    }
    return buckets;
  }

  Future<Map<DateTime,int>> fetchLast30DaysCounts(String driverId) async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day).subtract(Duration(days: 29));
    final snap = await _db
        .collection('detections')
<<<<<<< Updated upstream
        .where('driverId', isEqualTo: driverId)
=======
<<<<<<< HEAD
        .where('uid', isEqualTo: driverId)
=======
        .where('driverId', isEqualTo: driverId)
>>>>>>> 16548fd9f372664a8405d77e23307aa5fba1743b
>>>>>>> Stashed changes
        .where('timestamp', isGreaterThan: Timestamp.fromDate(start))
        .get();

    final map = <DateTime,int>{
      for (var i = 0; i < 30; i++)
        DateTime(start.year, start.month, start.day + i): 0
    };

    for (var doc in snap.docs) {
      final dt = (doc['timestamp'] as Timestamp).toDate();
      final day = DateTime(dt.year, dt.month, dt.day);
      if (map.containsKey(day)) map[day] = map[day]! + 1;
    }
    return map;
  }
<<<<<<< Updated upstream
}
=======
<<<<<<< HEAD


  Future<Map<DateTime,int>> fetchDailyCountsForMonth(
      String driverId, DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final startOfNext =
    DateTime(month.year, month.month + 1, 1);
    final snap = await _db
        .collection('detections')
        .where('uid', isEqualTo: driverId)
        .where('timestamp',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('timestamp',
        isLessThan: Timestamp.fromDate(startOfNext))
        .get();

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final map = {
      for (var d = 1; d <= daysInMonth; d++)
        DateTime(month.year, month.month, d): 0
    };

    for (var doc in snap.docs) {
      final dt = (doc['timestamp'] as Timestamp).toDate();
      final day = DateTime(dt.year, dt.month, dt.day);
      if (map.containsKey(day)) map[day] = map[day]! + 1;
    }
    return map;
  }
=======
>>>>>>> 16548fd9f372664a8405d77e23307aa5fba1743b
}
>>>>>>> Stashed changes
