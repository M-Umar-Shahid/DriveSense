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
    final total = data.values.fold<int>(0, (sum, v) => sum + v);
    final sections = <PieChartSectionData>[];
    data.forEach((label, count) {
      final color = _colorForLabel(label);
      sections.add(PieChartSectionData(
        value: count.toDouble(),
        color: color,
        title: '${((count / total) * 100).toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
      ));
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: data.keys.map((label) {
              return _LegendItem(
                color: _colorForLabel(label),
                label: label,
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
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}