import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drivesense/screens/login_signup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'edit_profile_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  String? _imageUrl;
  bool _audioAlertsEnabled = true;
  bool _openToWork = false;

  late AnimationController _animationController;
  late Animation<double> _profileAnimation;
  late Animation<double> _menuAnimation;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _profileAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _menuAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _animationController.forward();

    // Load saved user data
    _loadUserData();
    _loadOpenToWork();
    _loadAudioToggle();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    await FirebaseAuth.instance.currentUser?.reload();
    final updatedUser = FirebaseAuth.instance.currentUser;
    setState(() {
      _imageUrl = updatedUser?.photoURL;
    });
  }

  Future<void> _loadOpenToWork() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      if (doc.exists) {
        setState(
                () => _openToWork = doc.data()?['openToWork'] as bool? ?? false);
      }
    }
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

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? pickedFile =
      await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      var currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        final cred = await FirebaseAuth.instance.signInAnonymously();
        currentUser = cred.user;
      }

      final bytes = await pickedFile.readAsBytes();
      final path = 'profile_pictures/${currentUser!.uid}.jpg';
      final ref = FirebaseStorage.instance.ref().child(path);
      await ref.putData(bytes);
      final url = await ref.getDownloadURL();

      await currentUser.updatePhotoURL(url);
      await currentUser.reload();
      setState(() => _imageUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Logout', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => const LoginSignupPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    // enforce light status bar icons on grey background
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    final displayName = user?.displayName ?? 'No Name';
    final email = user?.email ?? 'No Email';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Profile Header
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _profileAnimation,
                builder: (context, child) => Opacity(
                  opacity: _profileAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - _profileAnimation.value)),
                    child: child,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                  child: Column(
                    children: [
                      // Avatar with gradient border
                      GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade400,
                                Colors.blue.shade600
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              child: ClipOval(
                                child: _imageUrl != null
                                    ? Image.network(
                                  _imageUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                )
                                    : const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Name
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                          shadows: [
                            Shadow(
                              blurRadius: 3,
                              color: Colors.black.withOpacity(0.1),
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Email pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.email_outlined,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Settings & Actions
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _menuAnimation,
                builder: (context, child) => Opacity(
                  opacity: _menuAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - _menuAnimation.value)),
                    child: child,
                  ),
                ),
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Open to work toggle
                      _buildToggleCard(
                        iconData: Icons.work_outline,
                        title: 'Open to work',
                        value: _openToWork,
                        onChanged: (v) {
                          setState(() => _openToWork = v);
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(user!.uid)
                              .update({'openToWork': v});
                        },
                      ),

                      const SizedBox(height: 16),

                      // Audio alerts toggle
                      _buildToggleCard(
                        iconData: Icons.volume_up,
                        title: 'Audio Alerts',
                        value: _audioAlertsEnabled,
                        onChanged: (v) {
                          setState(() => _audioAlertsEnabled = v);
                          _saveAudioToggle(v);
                        },
                      ),

                      const SizedBox(height: 16),

                      // Edit Profile
                      _buildOptionCard(
                        iconData: Icons.person_outlined,
                        title: 'Edit Profile',
                        subtitle: 'Update your personal info',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const EditProfilePage()),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Change Password
                      _buildOptionCard(
                        iconData: Icons.lock_outlined,
                        title: 'Change Password',
                        subtitle: 'Send reset email',
                        onTap: () async {
                          if (user?.email != null) {
                            await FirebaseAuth.instance
                                .sendPasswordResetEmail(
                                email: user!.email!);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                    Text('Password reset email sent!')),
                              );
                            }
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // About DriveSense
                      _buildOptionCard(
                        iconData: Icons.info_outline,
                        title: 'About DriveSense',
                        subtitle: 'App version & legal',
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: 'DriveSense',
                            applicationVersion: 'v1.0.0',
                            applicationLegalese: '© 2025 DriveSense Inc.',
                          );
                        },
                      ),

                      const SizedBox(height: 30),

                      // Logout button
                      _buildActionButton(
                        title: 'Log Out',
                        iconData: Icons.logout,
                        isPrimary: true,
                        onTap: _showLogoutDialog,
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required IconData iconData,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.1),
                Colors.blue.withOpacity(0.2)
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(iconData, color: Colors.blue, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        trailing: Switch(
          value: value,
          activeColor: Colors.blue,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData iconData,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.1),
                    Colors.blue.withOpacity(0.2)
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, color: Colors.blue, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_forward_ios,
                  color: Colors.grey[500], size: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData iconData,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(iconData),
        label: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.blue : Colors.white,
          foregroundColor: isPrimary ? Colors.white : Colors.grey[800],
          elevation: isPrimary ? 4 : 0,
          shadowColor:
          isPrimary ? Colors.blue.withOpacity(0.4) : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isPrimary ? Colors.transparent : Colors.grey[300]!,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}
