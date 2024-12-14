import 'package:flutter/material.dart';

class MonitoringPage extends StatelessWidget {
  const MonitoringPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E21), // Dark background color
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Navigation Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Text(
                    'Real time Monitoring',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),

              SizedBox(height: 20.0),

              // Driver's View Section
              Text(
                "Driver's View",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10.0),
              Stack(
                children: [
                  Container(
                    height: 200.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      image: DecorationImage(
                        image: AssetImage('assets/images/driver-view.png'), // Replace with your image
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10.0,
                    right: 10.0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        'Camera is Active',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.0),

              // Driver's Status Section
              Text(
                "Driver's Status",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statusIndicator('Awake', Colors.green),
                  _statusIndicator('Drowsy', Colors.red),
                  _statusIndicator('Seat belt', Colors.green),
                ],
              ),

              SizedBox(height: 20.0),

              // Recent Alerts Section
              Text(
                'Recent Alerts',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10.0),
              Expanded(
                child: ListView(
                  children: [
                    _alertTile('Distract detected', '5 minutes ago'),
                    _alertTile('Seatbelt not fastened', '5 minutes ago'),
                    _alertTile('Phone usage detected', '10 minutes ago'),
                  ],
                ),
              ),

              // Bottom Navigation Bar
              _bottomNavigationBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusIndicator(String label, Color color) {
    return Column(
      children: [
        Container(
          width: 50.0,
          height: 50.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
          ),
          child: Center(
            child: Container(
              width: 30.0,
              height: 30.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
          ),
        ),
        SizedBox(height: 5.0),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.0,
          ),
        ),
      ],
    );
  }

  Widget _alertTile(String alert, String time) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 0.0),
      leading: Icon(Icons.warning, color: Colors.redAccent),
      title: Text(
        alert,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14.0,
        ),
      ),
      subtitle: Text(
        time,
        style: TextStyle(
          color: Colors.grey,
          fontSize: 12.0,
        ),
      ),
      trailing: Text(
        'Clear',
        style: TextStyle(
          color: Colors.blueAccent,
          fontSize: 12.0,
        ),
      ),
    );
  }

  Widget _bottomNavigationBar() {
    return BottomNavigationBar(
      backgroundColor: Color(0xFF0A0E21),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.camera),
          label: 'Camera',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map),
          label: 'Map',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'Analytics',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

void main() => runApp(MaterialApp(
  home: MonitoringPage(),
));
