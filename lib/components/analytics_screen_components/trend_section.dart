import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TrendSection extends StatelessWidget {
  final List<int> weeklyCounts;
  const TrendSection({
    required this.weeklyCounts,
    super.key
  });
  @override
  Widget build(BuildContext context) {
    return BarChart(
        BarChartData(
          barTouchData: BarTouchData(enabled: true),
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
              bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, getTitlesWidget: _getBottomTitles, reservedSize: 20)
              )
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                    toY: weeklyCounts[i].toDouble(),
                    width: 20,
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.blueAccent
                )
              ]
          )),
        )
    );
  }

  Widget _getBottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.grey, fontSize: 12);
    const titles = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
    return SideTitleWidget(axisSide: meta.axisSide, child: Text(titles[value.toInt()], style: style));
  }
}
