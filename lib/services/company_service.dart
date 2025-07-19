// lib/services/company_service.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
      'driverIds': <String>[], // ← NEW: start with no drivers
      'avgRating': 0.0, // ← NEW: initial average rating
      'adminId': uid, // ← NEW: creator is admin
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

    final now = Timestamp.now();

    // 1) Add to the company’s driverIds as before
    await compRef.update({
      'driverIds': FieldValue.arrayUnion([driverId]),
    });

    // 2) In a transaction, upsert the assignment entry
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final data = snap.data() as Map<String, dynamic>;
      final raw = (data['assignments'] as List<dynamic>?) ?? [];
      final assigns = raw.cast<Map<String, dynamic>>();

      var updated = false;
      for (var entry in assigns) {
        if (entry['companyId'] == companyId) {
          // overwrite the existing stint
          entry['dateHired'] = now;
          entry['dateLeft'] = null;
          entry['status'] = 'active';
          updated = true;
          break;
        }
      }
      if (!updated) {
        // first time hire → add new stint
        assigns.add({
          'companyId': companyId,
          'dateHired': now,
          'dateLeft': null,
          'status': 'active',
        });
      }

      // 3) Write back both arrays + openToWork
      tx.update(userRef, {
        'companyHistory': FieldValue.arrayUnion([companyId]),
        // still use arrayUnion
        'assignments': assigns,
        'openToWork': false,
      });
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
    await _firestore.collection('ratings').where(
        'driverId', isEqualTo: driverId).get();
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
    final now = Timestamp.now();

    await compRef.update({
      'driverIds': FieldValue.arrayUnion([driverId]),
    });

    await userRef.update({
      'company': companyId, // optional if you need it
      'openToWork': false,
      'companyHistory': FieldValue.arrayUnion([companyId]),
      'assignments': FieldValue.arrayUnion([
        {
          'companyId': companyId,
          'dateHired': now,
          'dateLeft': null,
          'status': 'active',
        }
      ]),
    });
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
    await _firestore.collection('companies').doc(companyId).collection(
        'ratings').doc(uid).set({
      'rating': rating,
      'timestamp': FieldValue.serverTimestamp(),
    });

    return true;
  }

  /// ─── G) GET AVERAGE RATING FOR A COMPANY (UNCHANGED) ─────────────────
  Future<double> getAverageCompanyRating(String companyId) async {
    final snap =
    await _firestore.collection('companies').doc(companyId).collection(
        'ratings').get();
    if (snap.docs.isEmpty) return 0.0;
    final sum = snap.docs
        .map((d) => (d.data()['rating'] as num).toDouble())
        .fold<double>(0, (a, b) => a + b);
    return sum / snap.docs.length;
  }

  /// ─── H) RATE COMPANY (UNCHANGED) ────────────────────────────────────
  Future<void> rateCompany(String companyId,
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
  Future<List<CompanyRating>> fetchRecentRatings(String companyId,
      {int limit = 5}) async {
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

    await FirebaseFirestore.instance.collection('companies')
        .doc(companyId)
        .update({'avgRating': avg});
  }

  /// ─── N) LEAVE COMPANY (NEW) ─────────────────────────────────────────
  ///
  /// Any member can call this to:
  /// 1) remove themselves from company’s `driverIds`
  /// 2) set their own `/users/{userId}.company = null`
  Future<void> leaveCompany(String companyId, String userId) async {
    final compRef = _firestore.collection('companies').doc(companyId);
    final userRef = _firestore.collection('users').doc(userId);
    final now = Timestamp.now();

    // 1) Remove from current employees
    await compRef.update({
      'driverIds': FieldValue.arrayRemove([userId]),
    });

    // 2) Update that user's assignment record & openToWork
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final assigns = List<Map>.from(snap['assignments'] as List);
      for (var a in assigns) {
        if (a['companyId'] == companyId && a['status'] == 'active') {
          a['status'] = 'inactive';
          a['dateLeft'] = now;
          break;
        }
      }
      tx.update(userRef, {
        'assignments': assigns,
        'openToWork': true,
      });
    });
  }

  /// ─── O) FIRE EMPLOYEE (NEW) ──────────────────────────────────────────
  ///
  /// Only the admin (adminId) can call this to remove another employee:
  /// 1) Verify requestor is admin
  /// 2) remove employeeId from company’s `driverIds`
  /// 3) set `/users/{employeeId}.company = null`
  Future<void> fireEmployee(String companyId, String adminId,
      String employeeId) async {
    final companyRef = _firestore.collection('companies').doc(companyId);
    final companySnap = await companyRef.get();
    if (companySnap['adminId'] != adminId) {
      throw Exception("Only the admin can fire employees.");
    }

    // 1) Remove from current employees
    await companyRef.update({
      'driverIds': FieldValue.arrayRemove([employeeId]),
    });

    // 2) Mark their assignment as 'fired'
    final userRef = _firestore.collection('users').doc(employeeId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final assigns = List<Map>.from(snap['assignments'] as List);
      for (var a in assigns) {
        if (a['companyId'] == companyId && a['status'] == 'active') {
          a['status'] = 'fired';
          a['dateLeft'] = Timestamp.now();
          break;
        }
      }
      tx.update(userRef, {
        'assignments': assigns,
        'openToWork': true,
      });
    });
  }

  Future<void> updateCompany(String companyId, {
    String? name,
    String? description,
    String? logoUrl,
  }) async {
    final Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (logoUrl != null) updates['logoUrl'] = logoUrl;

    if (updates.isNotEmpty) {
      await _firestore
          .collection('companies')
          .doc(companyId)
          .update(updates);
    }
  }
    Future<String> uploadCompanyLogo(String companyId, File imageFile) async {
      // 1) Create a storage ref under "company_logos/{companyId}.png"
      final ref = FirebaseStorage.instance
          .ref()
          .child('company_logos')
          .child('$companyId.png');

      // 2) Upload the file
      await ref.putFile(imageFile);

      // 3) Get its URL
      return await ref.getDownloadURL();
    }
}