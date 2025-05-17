import 'package:flutter/material.dart';
import 'metric_card.dart';

class MetricsSection extends StatelessWidget {
  final int totalAlerts;
  final double totalHours;
  final String recommendation;

  const MetricsSection({
    required this.totalAlerts,
    required this.totalHours,
    required this.recommendation,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MetricCard(
          icon: Icons.av_timer,
          label: 'Total Hours',
          value: '${totalHours.toStringAsFixed(1)} hrs',
          color: Colors.deepPurple,
        ),
        const SizedBox(height: 12),
        MetricCard(
          icon: Icons.warning_amber_rounded,
          label: 'Alerts',
          value: '$totalAlerts',
          color: Colors.redAccent,
        ),
        const SizedBox(height: 12),
        MetricCard(
          icon: Icons.lightbulb,
          label: 'Recommendation',
          value: recommendation,
          color: Colors.teal,
        ),
      ],
    );
  }
}
