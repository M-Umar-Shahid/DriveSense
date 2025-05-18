import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/company_rating.dart';

class CompanyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createCompany({
    required String companyId,
    required String companyName,
    required String email,
  }) async {
    await _firestore.collection('companies').doc(companyId).set({
      'companyName': companyName,
      'email': email,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> addDriverToCompany({
    required String companyId,
    required String driverId,
  }) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .update({
      'driverIds': FieldValue.arrayUnion([driverId]),
    });
  }
  Future<List<String>> getCompanyDriverIds(String companyId) async {
    final doc = await _firestore.collection('companies').doc(companyId).get();
    final data = doc.data();
    return List<String>.from(data?['driverIds'] ?? []);
  }
  Future<double> getAverageRating(String driverId) async {
    final snap = await _firestore
        .collection('ratings')
        .where('driverId', isEqualTo: driverId)
        .get();
    if (snap.docs.isEmpty) return 0.0;
    final total = snap.docs.fold<double>(
      0,
          (sum, doc) => sum + (doc.data()['rating'] as num).toDouble(),
    );
    return total / snap.docs.length;
  }
  Future<void> hireDriver(String companyId, String driverId) async {
    final compRef = _firestore.collection('companies').doc(companyId);
    final userRef = _firestore.collection('users').doc(driverId);

    // 1) add driverId to the company
    await compRef.update({
      'driverIds': FieldValue.arrayUnion([driverId]),
    });

    // 2) assign the company on the user
    await userRef.update({'company': companyId});
  }

  // A) Submit a new rating
  Future<void> submitRating({
    required String companyId,
    required double rating,
    String? comment,
  }) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _firestore.collection('company_ratings').add({
      'companyId': companyId,
      'userId':    uid,
      'rating':    rating,
      'comment':   comment,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // B) Compute average rating
  Future<double> getAverageCompanyRating(String companyId) async {
    final snap = await _firestore
        .collection('company_ratings')
        .where('companyId', isEqualTo: companyId)
        .get();
    if (snap.docs.isEmpty) return 0.0;
    final total = snap.docs.fold<double>(
      0.0,
          (sum, doc) => sum + (doc.data()['rating'] as num).toDouble(),
    );
    return total / snap.docs.length;
  }

  // C) Count total ratings (for “x reviews”)
  Future<int> getCompanyRatingCount(String companyId) async {
    final snap = await _firestore
        .collection('company_ratings')
        .where('companyId', isEqualTo: companyId)
        .get();
    return snap.size;
  }

  // D) Fetch recent reviews for display
  Future<List<CompanyRating>> fetchRecentRatings(String companyId, {int limit = 5}) async {
    final snap = await _firestore
        .collection('company_ratings')
        .where('companyId', isEqualTo: companyId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => CompanyRating.fromFirestore(d)).toList();
  }

}
