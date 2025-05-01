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

  Future<DashboardStats> fetchStats() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint("⚠️ fetchStats: no currentUser");
      return DashboardStats(alertCount: 0, tripCount: 0, focusPercentage: 0);
    }
    debugPrint("🔍 fetchStats for uid = ${user.uid}");

    final alertsSnap = await _db
        .collection('detections')
        .where('uid', isEqualTo: user.uid)
        .get();
    debugPrint("   detections count = ${alertsSnap.size}");

    final tripsSnap = await _db
        .collection('trips')
        .where('uid', isEqualTo: user.uid)
        .get();
    debugPrint("   trips count      = ${tripsSnap.size}");

    final safeTrips = tripsSnap.docs.where((d) => (d['status'] as String?) == 'Safe').length;
    final totalTrips = tripsSnap.size;
    double focus = totalTrips > 0 ? safeTrips / totalTrips * 100 : 0;

    debugPrint("   safeTrips = $safeTrips, focus% = $focus");

    return DashboardStats(
      alertCount: alertsSnap.size,
      tripCount: totalTrips,
      focusPercentage: focus,
    );
  }


  Future<List<Trip>> fetchAllTrips() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snap = await FirebaseFirestore.instance
        .collection('trips')
        .where('uid', isEqualTo: user.uid)
        .orderBy('startTime', descending: true)
        .get();

    return snap.docs.map((doc) {
      // doc.data() is Map<String,dynamic>
      return Trip.fromMap(
        doc.id,                  // ← supply the document ID here
        doc.data() as Map<String, dynamic>,
      );
    }).toList();
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

    return snap.docs.map((doc) {
      // doc.data() is Map<String,dynamic>
      return Trip.fromMap(
        doc.id,                 // ← supply the Firestore document ID
        doc.data() as Map<String, dynamic>,
      );
    }).toList();
  }

}
