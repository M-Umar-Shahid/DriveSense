import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {
  final String username;
  final VoidCallback onProfileTap;
  const DashboardHeader({
    required this.username,
    required this.onProfileTap,
    super.key
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1976D2),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 25, 20, 35),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hi, $username 👋',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              IconButton(
                onPressed: onProfileTap,
                icon: Icon(Icons.person, color: Colors.white, size: 28),
              ),
            ],
          ),
          SizedBox(height: 15),
          Text(
            "This Month's Overview",
            style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}
