import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class MonitoringPage extends StatelessWidget {
  const MonitoringPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Light background color
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
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const Text(
                    'Real time Monitoring',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.black),
                    onPressed: () {},
                  ),
                ],
              ),

              const SizedBox(height: 20.0),

              // Driver's View Section
              const Text(
                "Driver's View",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10.0),
              Stack(
                children: [
                  Container(
                    height: 200.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/driver-view.png'), // Replace with your image
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10.0,
                    right: 10.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Text(
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

              const SizedBox(height: 20.0),

              // Driver's Status Section
              const Text(
                "Driver's Status",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statusIndicator('Awake', Colors.green),
                  _statusIndicator('Drowsy', Colors.red),
                  _statusIndicator('Seat belt', Colors.green),
                ],
              ),

              const SizedBox(height: 20.0),

              // Recent Alerts Section
              const Text(
                'Recent Alerts',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10.0),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusIndicator(String label, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60.0,
              height: 60.0,
              child: CircularProgressIndicator(
                value: 0.5, // Adjust value dynamically as needed
                strokeWidth: 5.0,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                backgroundColor: Colors.grey[300],
              ),
            ),
            Container(
              width: 30.0,
              height: 30.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 5.0),
        Text(
          label,
          style: TextStyle(
            color: Colors.black,
            fontSize: 12.0,
          ),
        ),
      ],
    );
  }

  Widget _alertTile(String alert, String time) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 0.0),
          leading: Icon(Icons.warning, color: Colors.redAccent),
          title: Text(
            alert,
            style: TextStyle(
              color: Colors.black,
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
        ),
      ],
    );
  }

}

void main() => runApp(MaterialApp(
  home: MonitoringPage(),
));
