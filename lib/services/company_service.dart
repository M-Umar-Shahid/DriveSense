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
  Future<bool> submitCompanyRating(String companyId, double rating) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    // 1) Verify membership at runtime (optional if you rely on security rules)
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final userCompany = userDoc.data()?['company'] as String?;
    if (userCompany != companyId) {
      // not a member → bail
      return false;
    }

    // 2) Write into companies/{companyId}/ratings/{uid}
    await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('ratings')
        .doc(uid)
        .set({
      'rating': rating,
      'timestamp': FieldValue.serverTimestamp(),
    });

    return true;
  }

  // B) Compute average rating
  Future<double> getAverageCompanyRating(String companyId) async {
    final snap = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('ratings')
        .get();
    if (snap.docs.isEmpty) return 0.0;
    final sum = snap.docs
        .map((d) => (d.data()['rating'] as num).toDouble())
        .fold<double>(0, (a, b) => a + b);
    return sum / snap.docs.length;
  }

  Future<void> rateCompany(
      String companyId,
      String userId,
      int stars, [
        String? comment,
      ]) async
  {
    final docId = userId;
    final data = {
      'userId':    userId,
      'rating':    stars,
      'timestamp': FieldValue.serverTimestamp(),
    };
    if (comment != null && comment.isNotEmpty) {
      data['comment'] = comment;
    }

    // 1) Create or overwrite the user’s rating doc
    await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('ratings')
        .doc(docId)
        .set(data);

    // 2) Recompute avgRating in the company doc
    await _updateCompanyAvg(companyId);
  }


  Future<double?> getMyCompanyRating(String companyId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('ratings')
        .doc(uid)
        .get();
    return doc.exists ? (doc.data()!['rating'] as num).toDouble() : null;
  }

  Future<int> getCompanyRatingCount(String companyId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('ratings')
        .get();

    return snapshot.docs.length;
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

  Future<int?> fetchUserRating(String companyId, String userId) async {
    final docRef = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('ratings')
        .doc(userId);

    final snapshot = await docRef.get();
    if (!snapshot.exists) return null;
    return (snapshot.data()?['rating'] as int?);
  }

  Future<void> _updateCompanyAvg(String companyId) async {
    final snap = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('ratings')
        .get();

    final docs = snap.docs;
    final count = docs.length;
    final totalStars = docs.fold<int>(
      0,
          (sum, doc) => sum + ((doc.data()['rating'] as int)),
    );
    final avg = (count == 0) ? 0.0 : totalStars / count;

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .update({'avgRating': avg});
  }

}
