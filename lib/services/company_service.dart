import 'package:cloud_firestore/cloud_firestore.dart';

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

}
