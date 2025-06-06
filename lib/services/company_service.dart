// lib/services/company_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/company_rating.dart';

class CompanyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ─── A) CREATE COMPANY (UPDATED) ─────────────────────────────────
  ///
  /// We add three new fields when creating a company:
  ///  1) 'driverIds': initialize as an empty array
  ///  2) 'avgRating': initialize to 0.0
  ///  3) 'adminId': set to the current user's UID (the “creator” becomes admin)
  Future<void> createCompany({
    required String companyId,
    required String companyName,
    required String email,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception("Must be signed in to create a company");
    }

    await _firestore.collection('companies').doc(companyId).set({
      'companyName': companyName,
      'email': email,
      'createdAt': Timestamp.now(),
      'driverIds': <String>[],        // ← NEW: start with no drivers
      'avgRating': 0.0,               // ← NEW: initial average rating
      'adminId': uid,                 // ← NEW: creator is admin
    });
  }

  /// ─── B) ADD DRIVER TO COMPANY (UPDATED) ────────────────────────────
  ///
  /// When you add a driver, you must:
  ///   1) push their UID into the company's `driverIds` array
  ///   2) set that user's `/users/{driverId}.company = companyId`
  Future<void> addDriverToCompany({
    required String companyId,
    required String driverId,
  }) async {
    final compRef = _firestore.collection('companies').doc(companyId);
    final userRef = _firestore.collection('users').doc(driverId);

    // 1) Add to the array of driver IDs
    await compRef.update({
      'driverIds': FieldValue.arrayUnion([driverId]),
    });

    // 2) Update the user's own document to point to this company
    await userRef.update({
      'company': companyId,
    });
  }

  /// ─── C) GET ALL DRIVER IDs ──────────────────────────────────────────
  Future<List<String>> getCompanyDriverIds(String companyId) async {
    final doc = await _firestore.collection('companies').doc(companyId).get();
    final data = doc.data();
    return List<String>.from(data?['driverIds'] ?? []);
  }

  /// ─── D) GET AVERAGE RATING FOR A DRIVER (UNCHANGED) ─────────────────
  Future<double> getAverageRating(String driverId) async {
    final snap =
    await _firestore.collection('ratings').where('driverId', isEqualTo: driverId).get();
    if (snap.docs.isEmpty) return 0.0;
    final total = snap.docs.fold<double>(
      0,
          (sum, doc) => sum + (doc.data()['rating'] as num).toDouble(),
    );
    return total / snap.docs.length;
  }

  /// ─── E) HIRE DRIVER (UNCHANGED) ─────────────────────────────────────
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

  /// ─── F) SUBMIT A NEW RATING (UNCHANGED) ─────────────────────────────
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
    await _firestore.collection('companies').doc(companyId).collection('ratings').doc(uid).set({
      'rating': rating,
      'timestamp': FieldValue.serverTimestamp(),
    });

    return true;
  }

  /// ─── G) GET AVERAGE RATING FOR A COMPANY (UNCHANGED) ─────────────────
  Future<double> getAverageCompanyRating(String companyId) async {
    final snap =
    await _firestore.collection('companies').doc(companyId).collection('ratings').get();
    if (snap.docs.isEmpty) return 0.0;
    final sum = snap.docs
        .map((d) => (d.data()['rating'] as num).toDouble())
        .fold<double>(0, (a, b) => a + b);
    return sum / snap.docs.length;
  }

  /// ─── H) RATE COMPANY (UNCHANGED) ────────────────────────────────────
  Future<void> rateCompany(
      String companyId,
      String userId,
      int stars, [
        String? comment,
      ]) async {
    final docId = userId;
    final data = {
      'userId': userId,
      'rating': stars,
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

  /// ─── I) GET “MY” RATING FOR THIS COMPANY (UNCHANGED) ─────────────────
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

  /// ─── J) GET COMPANY RATING COUNT (UNCHANGED) ─────────────────────────
  Future<int> getCompanyRatingCount(String companyId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('ratings')
        .get();

    return snapshot.docs.length;
  }

  /// ─── K) FETCH RECENT REVIEWS (UNCHANGED) ─────────────────────────────
  Future<List<CompanyRating>> fetchRecentRatings(String companyId, {int limit = 5}) async {
    final snap = await _firestore
        .collection('company_ratings')
        .where('companyId', isEqualTo: companyId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => CompanyRating.fromFirestore(d)).toList();
  }

  /// ─── L) FETCH A SPECIFIC USER’S RATING (UNCHANGED) ──────────────────
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

  /// ─── M) RECOMPUTE COMPANY AVERAGE (UNCHANGED) ───────────────────────
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

    await FirebaseFirestore.instance.collection('companies').doc(companyId).update({'avgRating': avg});
  }

  /// ─── N) LEAVE COMPANY (NEW) ─────────────────────────────────────────
  ///
  /// Any member can call this to:
  /// 1) remove themselves from company’s `driverIds`
  /// 2) set their own `/users/{userId}.company = null`
  Future<void> leaveCompany(String companyId, String userId) async {
    final userRef = _firestore.collection('users').doc(userId);
    final companyRef = _firestore.collection('companies').doc(companyId);

    // 1) Remove userId from driverIds array
    await companyRef.update({
      'driverIds': FieldValue.arrayRemove([userId]),
    });

    // 2) Set user's "company" field to null
    await userRef.update({
      'company': null,
    });
  }

  /// ─── O) FIRE EMPLOYEE (NEW) ──────────────────────────────────────────
  ///
  /// Only the admin (adminId) can call this to remove another employee:
  /// 1) Verify requestor is admin
  /// 2) remove employeeId from company’s `driverIds`
  /// 3) set `/users/{employeeId}.company = null`
  Future<void> fireEmployee(String companyId, String adminId, String employeeId) async {
    final companyRef = _firestore.collection('companies').doc(companyId);

    // 1) Ensure caller is the admin for this company
    final companySnapshot = await companyRef.get();
    final data = companySnapshot.data() as Map<String, dynamic>? ?? {};
    final storedAdminId = data['adminId'] as String?;
    if (storedAdminId == null || storedAdminId != adminId) {
      throw Exception("Only the company admin can fire employees.");
    }
    if (employeeId == adminId) {
      throw Exception("Admin cannot fire themselves.");
    }

    // 2) Remove that employee’s UID from driverIds
    await companyRef.update({
      'driverIds': FieldValue.arrayRemove([employeeId]),
    });

    // 3) Set that user’s company field to null
    await _firestore.collection('users').doc(employeeId).update({
      'company': null,
    });
  }
}
