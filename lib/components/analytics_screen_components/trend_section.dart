import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TrendSection extends StatelessWidget {
  final List<int> counts;
  final bool isSparkline;
  final bool showXAxis;

  /// `counts` is hourly or daily values.
  const TrendSection({
    Key? key,
    required this.counts,
    this.isSparkline = false,
    this.showXAxis = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isSparkline) {
      // Simple sparkline with gradient fill
      return SizedBox(
        height: 80,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: showXAxis,
                  reservedSize: 22,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: counts
                    .asMap()
                    .entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                    .toList(),
                isCurved: true,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.8),
                    Theme.of(context).primaryColor.withOpacity(0.2)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.4),
                      Colors.transparent
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                dotData: FlDotData(show: false),
                barWidth: 2,
              ),
            ],
          ),
        ),
      );
    }

    // Bar chart for weekly or daily counts
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, ctx) {
                  final idx = value.toInt();
                  final label = idx < counts.length ? '${idx + 1}' : '';
                  return SideTitleWidget(
                    axisSide: ctx.axisSide,
                    child: Text(label, style: const TextStyle(fontSize: 10)),
                  );
                },
                interval: 1,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 28),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: counts
              .asMap()
              .entries
              .map((e) => BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.toDouble(),
                width: 14,
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7)
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              )
            ],
          ))
              .toList(),
        ),
      ),
    );
  }
}