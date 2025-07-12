import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import '../models/alert.dart';
import '../models/dashboard_stats.dart';
import '../models/trip.dart';

class DashboardService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> fetchUsername() async {
    final user = _auth.currentUser;
    if (user == null) return 'User';
    return user.displayName ?? user.email?.split('@').first ?? 'User';
  }

  Future<DashboardStats> fetchStatsForUser(String uid) async {
    final alertsSnap = await _db
        .collection('detections')
        .where('uid', isEqualTo: uid)
        .get();

    final tripsSnap = await _db
        .collection('trips')
        .where('uid', isEqualTo: uid)
        .get();

    final safeTrips = tripsSnap.docs.where((d) => (d['status'] as String?) == 'Safe').length;
    final totalTrips = tripsSnap.size;
    double focus = totalTrips > 0 ? safeTrips / totalTrips * 100 : 0;

    return DashboardStats(
      alertCount: alertsSnap.size,
      tripCount: totalTrips,
      focusPercentage: focus,
    );
  }

  Future<List<Trip>> fetchAllTrips({required String driverId}) async {
    final snap = await _db
        .collection('trips')
        .where('uid', isEqualTo: driverId)
        .orderBy('startTime', descending: true)
        .get();

    return snap.docs
    // 1️⃣ Try to build a Trip? but bail out if either timestamp is null
        .map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      // safe‐cast to Timestamp?
      final Timestamp? startTs = data['startTime'] as Timestamp?;
      final Timestamp? endTs   = data['endTime']   as Timestamp?;

      if (startTs == null || endTs == null) {
        // skip this one entirely
        return null;
      }

      // you know for sure these are non-null, so your fromMap will succeed
      return Trip.fromMap(doc.id, data);
    })
    // 2️⃣ Drop all the nulls
        .whereType<Trip>()
        .toList();
  }



  Future<List<Alert>> fetchAlertsForTrip(String tripDocId) async {
    final snap = await FirebaseFirestore.instance
        .collection('trips')
        .doc(tripDocId)
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .get();

    return snap.docs.map((doc) {
      return Alert.fromMap(
        doc.id,
        doc.data() as Map<String, dynamic>,
      );
    }).toList();
  }



  Future<List<Trip>> fetchRecentTrips({int limit = 3}) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snap = await _db
        .collection('trips')
        .where('uid', isEqualTo: user.uid)
        .orderBy('endTime', descending: true)
        .limit(limit)
        .get();

    return snap.docs
        .map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final Timestamp? startTs = data['startTime'] as Timestamp?;
      final Timestamp? endTs   = data['endTime']   as Timestamp?;
      if (startTs == null || endTs == null) return null;
      return Trip.fromMap(doc.id, data);
    })
        .whereType<Trip>()
        .toList();
  }

}
