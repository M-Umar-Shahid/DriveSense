// lib/components/analytics_screen_components/pie_breakdown.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PieBreakdown extends StatelessWidget {
  final Map<String, int> data;
  final bool showLegend;

  const PieBreakdown({
    Key? key,
    required this.data,
    this.showLegend = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sum up all counts
    final total = data.values.fold<int>(0, (sum, v) => sum + v);

    // If there's no data, show a placeholder
    if (data.isEmpty || total == 0) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text(
          'No alerts for this period',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    // Build the pie sections
    final sections = <PieChartSectionData>[];
    data.forEach((label, count) {
      final percent = (count / total) * 100;
      sections.add(
        PieChartSectionData(
          value: count.toDouble(),
          color: _colorForLabel(label),
          title: '${percent.toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
        ),
      );
    });

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 24,
              sectionsSpace: 2,
            ),
          ),
        ),

        if (showLegend) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: data.entries.map((e) {
              return _LegendItem(
                color: _colorForLabel(e.key),
                label: '${e.key} (${e.value})',
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Color _colorForLabel(String label) {
    switch (label) {
      case 'Drowsy':
        return Colors.orange;
      case 'Distraction':
        return Colors.red;
      case 'Yawning':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    Key? key,
    required this.color,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
