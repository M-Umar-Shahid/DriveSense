import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileService {
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  User? get currentUser => _auth.currentUser;

  Future<String?> pickAndUploadImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    final uid = currentUser?.uid;
    if (uid == null) return null;
    final ref = _storage.ref().child('profile_pictures/$uid.jpg');
    await ref.putData(bytes);
    return await ref.getDownloadURL();
  }

  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    final user = currentUser;
    if (user == null) return;
    if (displayName != null) await user.updateDisplayName(displayName);
    if (photoUrl != null) await user.updatePhotoURL(photoUrl);
    await user.reload();
  }
}
