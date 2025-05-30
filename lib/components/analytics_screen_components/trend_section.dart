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
      return SizedBox(
        height: 80,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: showXAxis
                    ? SideTitles(showTitles: true, reservedSize: 22)
                    : SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
<<<<<<< Updated upstream
=======
<<<<<<< HEAD
              // For sparkline (Day view)
=======
>>>>>>> 16548fd9f372664a8405d77e23307aa5fba1743b
>>>>>>> Stashed changes
              LineChartBarData(
                spots: List.generate(
                  counts.length,
                      (i) => FlSpot(i.toDouble(), counts[i].toDouble()),
                ),
                isCurved: true,
<<<<<<< Updated upstream
                dotData: FlDotData(show: false),
                color: Theme.of(context).primaryColor,
                barWidth: 2,
=======
<<<<<<< HEAD
                gradient: LinearGradient(
                  colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.3)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [Theme.of(context).primaryColor.withOpacity(0.4), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                dotData: FlDotData(show: true),
=======
                dotData: FlDotData(show: false),
                color: Theme.of(context).primaryColor,
                barWidth: 2,
>>>>>>> 16548fd9f372664a8405d77e23307aa5fba1743b
>>>>>>> Stashed changes
              ),
            ],
          ),
        ),
      );
    }

    // Bar chart (weekly/daily)
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  final label = idx < counts.length ? '${idx + 1}' : '';
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(label, style: const TextStyle(fontSize: 10)),
                  );
                },
                interval: 1,
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(counts.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: counts[i].toDouble(),
<<<<<<< Updated upstream
                  color: Theme.of(context).primaryColor,
                  width: 12,
                  borderRadius: BorderRadius.circular(4),
=======
<<<<<<< HEAD
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent, Colors.lightBlueAccent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 14,
                  borderRadius: BorderRadius.circular(6),
=======
                  color: Theme.of(context).primaryColor,
                  width: 12,
                  borderRadius: BorderRadius.circular(4),
>>>>>>> 16548fd9f372664a8405d77e23307aa5fba1743b
>>>>>>> Stashed changes
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
