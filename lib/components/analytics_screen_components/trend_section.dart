import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TrendSection extends StatelessWidget {
  final List<int> weeklyCounts;
  const TrendSection({ required this.weeklyCounts, Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // guard empty
    if (weeklyCounts.isEmpty) {
      return const Center(child: Text('No data'));
    }

    // compute X and Y bounds
    final maxX = (weeklyCounts.length - 1).toDouble();
    final maxCount = weeklyCounts.reduce((a, b) => a > b ? a : b).toDouble();
    final yInterval = (maxCount > 0) ? (maxCount / 5).ceilToDouble() : 1.0;

    // build our spots
    final spots = List<FlSpot>.generate(
      weeklyCounts.length,
          (i) => FlSpot(i.toDouble(), weeklyCounts[i].toDouble()),
    );

    return SizedBox(
      height: 200,           // <-- FIXED height!
      width: double.infinity,
      child: LineChart(
        LineChartData(
          // enforce bounds so FL never divides by zero
          minX: 0,
          maxX: maxX,
          minY: 0,
          maxY: maxCount == 0 ? 1 : maxCount,

          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval,
          ),

          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: yInterval,
                reservedSize: 30,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,                             // one label per day
                getTitlesWidget: _bottomTitle,
              ),
            ),
          ),

          borderData: FlBorderData(show: false),

          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3,
              color: Colors.orangeAccent,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomTitle(double value, TitleMeta meta) {
    const labels = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
    final idx = value.toInt().clamp(0, labels.length - 1);
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(labels[idx], style: const TextStyle(color: Colors.grey, fontSize: 12)),
    );
  }
}
