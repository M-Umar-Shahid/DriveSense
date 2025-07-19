import 'package:flutter/material.dart';

class ProfilePicturePicker extends StatelessWidget {
  final String? imageUrl;
  final bool isLoading;
  final VoidCallback onEdit;
  const ProfilePicturePicker({
    required this.imageUrl,
    required this.onEdit,
    this.isLoading = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        isLoading
            ? SizedBox(
          width: 120,
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        )
            : CircleAvatar(
          radius: 60,
          backgroundImage: imageUrl != null
              ? NetworkImage(imageUrl!)
              : AssetImage('assets/images/profile.jpg') as ImageProvider,
        ),
        Positioned(
          bottom: 0,
          right: 4,
          child: GestureDetector(
            onTap: onEdit,
            child: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blueAccent),
              padding: EdgeInsets.all(6),
              child: Icon(Icons.edit, size: 18, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
