import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  String? _imageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController.text = user?.displayName ?? "";
    _imageUrl = user?.photoURL;
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      setState(() => _isLoading = true);

      final fileBytes = await pickedFile.readAsBytes();
      final fileName = "profile_pictures/${user.uid}.jpg";
      final ref = FirebaseStorage.instance.ref().child(fileName);

      await ref.putData(fileBytes);
      final downloadUrl = await ref.getDownloadURL();

      await user.updatePhotoURL(downloadUrl);
      await user.reload();

      setState(() {
        _imageUrl = downloadUrl;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    await user.updateDisplayName(_nameController.text.trim());
    await user.reload();

    setState(() => _isLoading = false);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context); // Return to profile screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Edit Profile", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Profile Picture
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: _imageUrl != null
                      ? NetworkImage(_imageUrl!)
                      : const AssetImage('assets/images/profile.jpg') as ImageProvider,
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blueAccent,
                      ),
                      padding: const EdgeInsets.all(6.0),
                      child: const Icon(Icons.edit, size: 18.0, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Name TextField
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                hintText: 'Enter your name',
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 40.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
              ),
              child: const Text("Save Changes", style: TextStyle(fontSize: 16, color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}
