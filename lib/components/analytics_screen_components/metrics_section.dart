// metrics_section.dart
import 'package:flutter/material.dart';
import 'metric_card.dart';

class MetricsSection extends StatelessWidget {
  final int totalAlerts;
  final double totalHours;
  final String recommendation;

  const MetricsSection({
    super.key,
    required this.totalAlerts,
    required this.totalHours,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MetricCard(
          icon: Icons.av_timer,
          label: 'Total Hours',
          value: '${totalHours.toStringAsFixed(1)} hrs',
          gradient: [
            Colors.deepPurple.shade400,
            Colors.deepPurple.shade200,
          ],
        ),
        const SizedBox(height: 12),
        MetricCard(
          icon: Icons.warning_amber_rounded,
          label: 'Alerts',
          value: '$totalAlerts',
          gradient: [
            Colors.redAccent.shade400,
            Colors.redAccent.shade200,
          ],
        ),
        const SizedBox(height: 12),
        MetricCard(
          icon: Icons.lightbulb,
          label: 'Recommendation',
          value: recommendation.isNotEmpty ? recommendation : '—',
          gradient: [
            Colors.teal.shade400,
            Colors.teal.shade200,
          ],
        ),
      ],
    );
  }
}
