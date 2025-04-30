import 'package:flutter/material.dart';
import '../../models/alert.dart';
import '../../services/image_alerts_service.dart';
import '../components/image_alerts_screen_component/alert_card.dart';
import '../components/image_alerts_screen_component/filter_dialog.dart';
import 'full_screen_image_view.dart';

class ImageAlertsPage extends StatefulWidget {
  const ImageAlertsPage({super.key});
  @override
  State<ImageAlertsPage> createState() => _ImageAlertsPageState();
}

class _ImageAlertsPageState extends State<ImageAlertsPage> {
  String _filter = 'All';
  final _service = ImageAlertsService();

  void _openFilter() {
    showDialog(
      context: context,
      builder: (_) => FilterDialog(
        selected: _filter,
        onSelected: (value) => setState(() => _filter = value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Image Alerts", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0.5,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.filter_alt_rounded, color: Colors.blueAccent), onPressed: _openFilter)],
      ),
      body: StreamBuilder<List<Alert>>(
        stream: _service.streamAlerts(_filter),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final alerts = snap.data;
          if (alerts == null || alerts.isEmpty) {
            return const Center(child: Text("No alerts found"));
          }
          return Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              itemCount: alerts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 3/4
              ),
              itemBuilder: (context, i) {
                final alert = alerts[i];
                return AlertCard(
                  alert: alert,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FullScreenImageView(imageUrl: alert.imageUrl)),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
