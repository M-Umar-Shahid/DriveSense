import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'main.dart';
import 'edit_profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with RouteAware{
  final user = FirebaseAuth.instance.currentUser;
  String? _imageUrl;
  bool _audioAlertsEnabled = true;


  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    await FirebaseAuth.instance.currentUser?.reload(); // 🔁 Refresh from server
    final updatedUser = FirebaseAuth.instance.currentUser;
    setState(() {
      _imageUrl = updatedUser?.photoURL;
    });
  }


  Future<void> _loadAudioToggle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _audioAlertsEnabled = prefs.getBool('audio_alerts') ?? true;
    });
  }

  Future<void> _saveAudioToggle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('audio_alerts', value);
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when returning to this screen
    _loadUserData(); // Re-fetch name & photo
  }


  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      var user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        final credential = await FirebaseAuth.instance.signInAnonymously();
        user = credential.user;
      }

      final fileBytes = await pickedFile.readAsBytes();
      final fileName = "profile_pictures/${user!.uid}.jpg";
      final ref = FirebaseStorage.instance.ref().child(fileName);

      await ref.putData(fileBytes);
      final downloadUrl = await ref.getDownloadURL();

      await user.updatePhotoURL(downloadUrl);
      await user.reload();
      setState(() => _imageUrl = downloadUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String name = user?.displayName ?? "No Name";
    final String email = user?.email ?? "No Email";

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button and Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 28.0, color: Colors.black54),
                  ),
                  const SizedBox(width: 10.0),
                  const Text(
                    "Profile",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // Profile Section
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60.0,
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
                  const SizedBox(height: 10.0),
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5.0),
                  Text(
                    email,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14.0,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30.0),

            // Settings List
            Expanded(
              child: ListView(
                children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                    title: const Text(
                      "Audio Alerts",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    secondary: const Icon(Icons.volume_up, color: Colors.black87),
                    activeColor: Colors.blueAccent, // Color of the thumb when enabled
                    activeTrackColor: Colors.blueAccent.withOpacity(0.3), // Track color when enabled
                    inactiveThumbColor: Colors.grey, // Thumb when off
                    inactiveTrackColor: Colors.grey.shade300, // Track when off
                    value: _audioAlertsEnabled,
                    onChanged: (value) {
                      setState(() => _audioAlertsEnabled = value);
                      // Save if needed
                    },
                  ),
                  const SizedBox(height: 20),
                  _settingsItem(
                    title: "Edit Profile",
                    icon: Icons.person,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditProfilePage()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _settingsItem(
                    title: "Change Password",
                    icon: Icons.lock,
                    onTap: () async {
                      final email = FirebaseAuth.instance.currentUser?.email;
                      if (email != null) {
                        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password reset email sent!')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No email available to reset password.')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  _settingsItem(
                    title: "About DriveSense",
                    icon: Icons.info,
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: "DriveSense",
                        applicationVersion: "v1.0.0",
                        applicationLegalese: "© 2025 DriveSense Inc.",
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _settingsItem(
                    title: "Logout",
                    icon: Icons.logout,
                    color: Colors.red,
                    onTap: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Confirm Logout"),
                          content: const Text("Are you sure you want to log out?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                "Logout",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (shouldLogout == true) {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10.0),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16.0,
                    color: color,
                  ),
                ),
              ],
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
