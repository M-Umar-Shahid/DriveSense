import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/detection.dart';

class AnalyticsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 1) Most recent N detections (for your “Recent Issues” lists)
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

    return snap.docs
        .map((d) => Detection.fromMap(d.data()))
        .toList();
  }

  /// 2) Hourly counts over the last 24h (for your day-view line chart)
  Future<List<int>> fetchHourlyCounts(String driverId) async {
    final now = DateTime.now();
    final cutOff = now.subtract(const Duration(hours: 24));

    final snap = await _db
        .collection('detections')
        .where('uid', isEqualTo: driverId)
        .where('timestamp', isGreaterThan: Timestamp.fromDate(cutOff))
        .get();

    var buckets = List<int>.filled(24, 0);
    for (var doc in snap.docs) {
      final ts = (doc['timestamp'] as Timestamp).toDate().toLocal();
      buckets[ts.hour]++;
    }
    return buckets;
  }

  /// 3) Weekly trends: counts for each of the last 7 days
  Future<List<int>> fetchWeeklyTrends(String driverId) async {
    final todayMidnight =
    DateTime.now().toLocal();
    final cutOff =
    DateTime(todayMidnight.year, todayMidnight.month, todayMidnight.day)
        .subtract(const Duration(days: 6));

    final snap = await _db
        .collection('detections')
        .where('uid', isEqualTo: driverId)
        .where('timestamp',
        isGreaterThanOrEqualTo: Timestamp.fromDate(cutOff))
        .get();

    var buckets = List<int>.filled(7, 0);
    for (var doc in snap.docs) {
      final dt = (doc['timestamp'] as Timestamp).toDate().toLocal();
      final day = DateTime(dt.year, dt.month, dt.day);
      final idx = day.difference(cutOff).inDays;
      if (idx >= 0 && idx < 7) buckets[idx]++;
    }
    return buckets;
  }

  /// 4) Daily counts for a specific month (for your heatmap)
  Future<Map<DateTime,int>> fetchDailyCountsForMonth(
      String driverId, DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final next  = DateTime(month.year, month.month + 1, 1);

    final snap = await _db
        .collection('detections')
        .where('uid', isEqualTo: driverId)
        .where('timestamp',
        isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(next))
        .get();

    // initialize every day of the month to zero
    final days = DateTime(month.year, month.month + 1, 0).day;
    final map = {
      for (var d = 1; d <= days; d++)
        DateTime(month.year, month.month, d): 0
    };

    for (var doc in snap.docs) {
      final dt = (doc['timestamp'] as Timestamp).toDate().toLocal();
      final day = DateTime(dt.year, dt.month, dt.day);
      if (map.containsKey(day)) map[day] = map[day]! + 1;
    }
    return map;
  }

  /// 5) Monthly breakdown by alertType (for your pie chart)
  Future<Map<String,int>> fetchMonthlyBreakdownForMonth(
      String driverId, DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final next  = DateTime(month.year, month.month + 1, 1);

    final snap = await _db
        .collection('detections')
        .where('uid', isEqualTo: driverId)
        .where('timestamp',
        isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(next))
        .get();

    final counts = <String,int>{};
    for (var doc in snap.docs) {
      final t = (doc.data()['alertType'] as String?) ?? 'Unknown';
      counts[t] = (counts[t] ?? 0) + 1;
    }
    return counts;
  }

  /// 6) Totals summary: totalAlerts, totalHours, recommendation
  Future<Map<String,dynamic>> fetchTotals(String driverId) async {
    final alertsSnap = await _db
        .collection('detections')
        .where('uid', isEqualTo: driverId)
        .get();
    final tripsSnap = await _db
        .collection('trips')
        .where('uid', isEqualTo: driverId)
        .get();

    final totalAlerts = alertsSnap.size;
    double totalHours = 0;
    for (var doc in tripsSnap.docs) {
      final data = doc.data();
      final startTs = data['startTime'] as Timestamp?;
      final endTs   = data['endTime']   as Timestamp?;
      if (startTs != null && endTs != null) {
        totalHours +=
            endTs.toDate().difference(startTs.toDate()).inMinutes / 60.0;
      }
    }

    // find most common alertType
    final typeCount = <String,int>{};
    for (var doc in alertsSnap.docs) {
      final t = (doc.data()['alertType'] as String?) ?? 'Unknown';
      typeCount[t] = (typeCount[t] ?? 0) + 1;
    }
    final most = typeCount.entries.fold<MapEntry<String,int>>(
      MapEntry('', 0),
          (prev, e) => e.value > prev.value ? e : prev,
    );

    String rec;
    switch (most.key) {
      case 'Drowsy':
        rec = 'Avoid drowsy driving';
        break;
      case 'Yawning':
        rec = 'Stay hydrated and rested';
        break;
      case 'No Seatbelt':
        rec = 'Always buckle up';
        break;
      case 'Distraction':
        rec = 'Keep your eyes on the road';
        break;
      default:
        rec = 'Keep up the safe driving!';
    }

    return {
      'totalAlerts': totalAlerts,
      'totalHours': totalHours,
      'recommendation': rec,
    };
  }

  /// 7) Last 30 days counts (for a longer heatmap if you ever need it)
  Future<Map<DateTime,int>> fetchLast30DaysCounts(String driverId) async {
    final today = DateTime.now().toLocal();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 29));

    final snap = await _db
        .collection('detections')
        .where('uid', isEqualTo: driverId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .get();

    final map = {
      for (var i = 0; i < 30; i++)
        DateTime(start.year, start.month, start.day + i): 0
    };

    for (var doc in snap.docs) {
      final dt = (doc['timestamp'] as Timestamp).toDate().toLocal();
      final day = DateTime(dt.year, dt.month, dt.day);
      if (map.containsKey(day)) map[day] = map[day]! + 1;
    }
    return map;
  }
}
