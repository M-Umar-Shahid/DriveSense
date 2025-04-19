// import 'package:curved_navigation_bar/curved_navigation_bar.dart';
// import 'package:drivesense/pages/profile_page.dart';
// import 'package:drivesense/pages/video_alerts_page.dart';
// import 'package:flutter/material.dart';
// import 'dashboard.dart';
//
// class BottomNavigation extends StatefulWidget {
//   const BottomNavigation({super.key});
//
//   @override
//   State<BottomNavigation> createState() => _BottomNavigationState();
// }
//
// class _BottomNavigationState extends State<BottomNavigation> {
//   int _currentIndex = 0; // Track the selected tab
//
//   // Pages to display based on selected index
//   final List<Widget> _pages = [
//     const Dashboard(),
//     VideoAlertsPage(),
//     const ProfilePage(),
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: _pages[_currentIndex], // Dynamically load pages
//       ),
//
//       // Curved Bottom Navigation Bar
//       bottomNavigationBar: CurvedNavigationBar(
//         backgroundColor: Colors.transparent,
//         color: Colors.blueAccent,
//         buttonBackgroundColor: Colors.blueAccent,
//         height: 60.0,
//         index: _currentIndex, // Current index
//         animationDuration: const Duration(milliseconds: 300),
//         items: const <Widget>[
//           Icon(Icons.home, size: 30, color: Colors.white),
//           Icon(Icons.receipt, size: 30, color: Colors.white),
//           Icon(Icons.person, size: 30, color: Colors.white),
//         ],
//         onTap: (index) {
//           setState(() {
//             _currentIndex = index; // Update the selected index
//           });
//         },
//       ),
//     );
//   }
// }
//
// // Custom Circular Button
// class CircularButton extends StatelessWidget {
//   final String text;
//   final String logoPath;
//   final VoidCallback onPressed;
//
//   const CircularButton({
//     required this.text,
//     required this.logoPath,
//     required this.onPressed,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton(
//       onPressed: onPressed,
//       style: ElevatedButton.styleFrom(
//         shape: const CircleBorder(),
//         backgroundColor: const Color(0xFF1976D2),
//         padding: const EdgeInsets.all(30.0),
//         elevation: 5.0,
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Image.asset(
//             logoPath,
//             width: 30.0,
//             height: 30.0,
//           ),
//           const SizedBox(height: 5.0),
//           Text(
//             text,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 14.0,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
