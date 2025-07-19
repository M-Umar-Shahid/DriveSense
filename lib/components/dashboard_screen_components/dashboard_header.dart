import 'package:flutter/material.dart';
import '../../screens/drivers_request_page.dart';

class DashboardHeader extends StatelessWidget {
  final String username;
  final VoidCallback onProfileTap;
  final bool showCompanies;
  final VoidCallback? onCompaniesTap;

  const DashboardHeader({
    super.key,
    required this.username,
    required this.onProfileTap,
    this.showCompanies = false,
    this.onCompaniesTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4285F4), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Greeting
              Expanded(
                child: Text(
                  'Hi, $username',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              // Optional companies icon
              if (showCompanies && onCompaniesTap != null) ...[
                IconButton(
                  onPressed: onCompaniesTap,
                  icon: const Icon(Icons.business),
                  color: Colors.white,
                  tooltip: 'Companies',
                ),
              ],

              // Hire requests button
              _RequestsButton(),

              // Profile icon
              IconButton(
                onPressed: onProfileTap,
                icon: const Icon(Icons.person),
                color: Colors.white,
                tooltip: 'Profile',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "This Month's Overview",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestsButton extends StatelessWidget {
  const _RequestsButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DriverRequestsPage()),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white70),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      icon: const Icon(Icons.email, size: 20, color: Colors.white),
      label: const Text(
        'Hire Requests',
        style: TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }
}
