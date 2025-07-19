import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> createCompany({
  required String companyId,
  required String companyName,
  required String email,
}) async {
  final firestore = FirebaseFirestore.instance;

  await firestore.collection('companies').doc(companyId).set({
    'companyName': companyName,
    'email': email,
    'createdAt': Timestamp.now(),
  });
}
