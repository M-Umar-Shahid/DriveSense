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
<<<<<<< Updated upstream
=======
<<<<<<< HEAD

    // Show placeholder if no data
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

=======
>>>>>>> 16548fd9f372664a8405d77e23307aa5fba1743b
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
                label: label,
=======
<<<<<<< HEAD
                label: '$label (${data[label]})',
=======
                label: label,
>>>>>>> 16548fd9f372664a8405d77e23307aa5fba1743b
>>>>>>> Stashed changes
              );
            }).toList(),
          ),
        ],
<<<<<<< Updated upstream
=======
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
<<<<<<< HEAD
        Text(label, style: const TextStyle(fontSize: 12)),
=======
        Text(label),
>>>>>>> 16548fd9f372664a8405d77e23307aa5fba1743b
>>>>>>> Stashed changes
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