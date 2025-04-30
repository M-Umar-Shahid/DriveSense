import 'package:flutter/material.dart';

import '../components/edit_profile_screen_components/custom_text_field.dart';
import '../components/edit_profile_screen_components/primary_button.dart';
import '../components/edit_profile_screen_components/profile_picture_picker.dart';
import '../services/profile_sevice.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _service = ProfileService();
  final _nameController = TextEditingController();
  String? _imageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = _service.currentUser;
    _nameController.text = user?.displayName ?? '';
    _imageUrl = user?.photoURL;
  }

  Future<void> _onEditImage() async {
    setState(() => _isLoading = true);
    final url = await _service.pickAndUploadImage();
    if (url != null) await _service.updateProfile(photoUrl: url);
    setState(() {
      _imageUrl = url;
      _isLoading = false;
    });
  }

  Future<void> _onSave() async {
    setState(() => _isLoading = true);
    await _service.updateProfile(displayName: _nameController.text.trim());
    setState(() => _isLoading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F6FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: Text('Edit Profile', style: TextStyle(color: Colors.black)),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            ProfilePicturePicker(
              imageUrl: _imageUrl,
              isLoading: _isLoading,
              onEdit: _onEditImage,
            ),
            SizedBox(height: 30),
            CustomTextField(controller: _nameController, label: 'Name'),
            SizedBox(height: 30),
            PrimaryButton(label: 'Save Changes', isLoading: _isLoading, onPressed: _onSave),
          ],
        ),
      ),
    );
  }
}
