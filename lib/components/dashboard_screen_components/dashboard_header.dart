import 'package:flutter/material.dart';

import '../../screens/drivers_request_page.dart';

class DashboardHeader extends StatelessWidget {
  final String username;
  final VoidCallback onProfileTap;
  final bool showCompanies;
  final VoidCallback? onCompaniesTap;

  const DashboardHeader({
    required this.username,
    required this.onProfileTap,
    this.showCompanies = false,
    this.onCompaniesTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1976D2),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 35),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hi, $username 👋',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  if (showCompanies && onCompaniesTap != null) ...[
                    IconButton(
                      onPressed: onCompaniesTap,
                      icon: const Icon(Icons.business, color: Colors.white, size: 28),
                      tooltip: 'Companies',
                    ),
                  ],
                  TextButton.icon(
                    icon: const Icon(Icons.email),
                    label: const Text('View Hire Requests'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DriverRequestsPage()),
                      );
                    },
                  ),
                  IconButton(
                    onPressed: onProfileTap,
                    icon: const Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            "This Month's Overview",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
