import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PieBreakdown extends StatelessWidget {
  final Map<String,int> monthlyCounts;
  const PieBreakdown({
    required this.monthlyCounts,
    super.key
  });
  @override
  Widget build(BuildContext context) {
    final total = monthlyCounts.values.fold<int>(0, (a, b) => a + b);
    final colors = [
      Colors.orangeAccent,
      Colors.deepPurpleAccent,
      Colors.green,
      Colors.pinkAccent,
      Colors.indigo,
      Colors.teal,
      Colors.cyan,
    ];
    final sections = total == 0
        ? [PieChartSectionData(color: Colors.grey[300], value: 1, showTitle: false)]
        : List.generate(monthlyCounts.length, (i) {
      final key = monthlyCounts.keys.elementAt(i);
      final value = monthlyCounts[key]!.toDouble();
      final percent = (value / total) * 100;
      return PieChartSectionData(
          color: colors[i % colors.length],
          value: value,
          title: percent < 5 ? '' : '${percent.toStringAsFixed(1)}%',
          titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          radius: 40
      );
    });
    final legend = List.generate(monthlyCounts.length, (i) {
      final key = monthlyCounts.keys.elementAt(i);
      return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[i % colors.length], shape: BoxShape.circle)),
            SizedBox(width: 6),
            Text(key, style: TextStyle(fontSize: 12)),
          ]
      );
    });
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 12, runSpacing: 8, children: legend),
          SizedBox(height: 12),
          SizedBox(
              height: 200,
              child: PieChart(PieChartData(sections: sections, sectionsSpace: 4, centerSpaceRadius: 40))
          )
        ]
    );
  }
}
