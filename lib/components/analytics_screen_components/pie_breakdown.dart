import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PieBreakdown extends StatelessWidget {
  final Map<String,int> monthlyCounts;
  const PieBreakdown({
    required this.monthlyCounts,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final total = monthlyCounts.values.fold<int>(0, (a, b) => a + b);
    final colors = [Colors.orange, Colors.deepPurple, Colors.green, Colors.redAccent, Colors.teal];
    final sections = total == 0
        ? [PieChartSectionData(color: Colors.grey[300]!, value: 1, showTitle: false)]
        : List.generate(monthlyCounts.length, (i) {
      final key = monthlyCounts.keys.elementAt(i);
      final value = monthlyCounts[key]!.toDouble();
      final pct = (value/total)*100;
      return PieChartSectionData(
        color: colors[i % colors.length],
        value: value,
        radius: 50,
        title: pct < 5 ? '' : '${pct.toStringAsFixed(1)}%',
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: List.generate(monthlyCounts.length, (i) {
            final key = monthlyCounts.keys.elementAt(i);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[i%colors.length], shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(key),
              ],
            );
          }),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 40,
              sections: sections,
            ),
          ),
        ),
      ],
    );
  }
}
