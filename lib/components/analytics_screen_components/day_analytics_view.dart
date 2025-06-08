import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/detection.dart';
import 'package:drivesense/components/analytics_screen_components/recent_detections_list.dart';
import 'package:drivesense/components/analytics_screen_components/metric_card.dart';

import 'build_chart_container.dart';

class DayAnalyticsView extends StatelessWidget {
  const DayAnalyticsView({
    super.key,
    required this.showComparison,
    required this.onComparisonChanged,
    required this.avgHourly,
    required this.peakHour,
    required this.hourlyCounts,
    required this.recentDetections,
    required this.selectedFilter,
    required this.filters,
    required this.onFilterChanged,
  });

  final bool showComparison;
  final ValueChanged<bool> onComparisonChanged;
  final double avgHourly;
  final int peakHour;
  final List<int> hourlyCounts;
  final List<Detection> recentDetections;
  final String selectedFilter;
  final List<String> filters;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final totalAlerts = hourlyCounts.fold<int>(0, (sum, v) => sum + v);
    final maxCount = hourlyCounts.isEmpty ? 0 : hourlyCounts.reduce(max);

    // Breakdown by type
    final byType = <String,int>{};
    for (var d in recentDetections) {
      byType[d.type] = (byType[d.type] ?? 0) + 1;
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today's Summary + Pie
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Container(
                // ← New: colored background for the summary + pie area
                decoration: BoxDecoration(
                  color: Colors.white,                    // change this to any Color you like
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            context,
                            'Total Alerts',
                            '$totalAlerts',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            context,
                            'Peak Hour',
                            '$peakHour:00',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      // ← New: background behind just the pie
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: SizedBox(
                        height: 140,
                        child: PieChart(
                          PieChartData(
                            sections: byType.entries.map((e) {
                              final color = e.key == 'Drowsy'
                                  ? Colors.redAccent
                                  : e.key == 'No Seatbelt'
                                  ? Colors.purple
                                  : Colors.orangeAccent;
                              return PieChartSectionData(
                                value: e.value.toDouble(),
                                title: '${e.key}\n${e.value}',
                                color: color,
                                radius: 40,
                                titleStyle: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                            centerSpaceRadius: 30,
                            sectionsSpace: 3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Hourly Trend
            Text('Hourly Trend', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Compare', style: TextStyle(color: Colors.grey[700])),
                Switch(value: showComparison, onChanged: onComparisonChanged),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [
              MetricCard(
                icon: Icons.show_chart,
                label: 'Avg / hr',
                value: avgHourly.toStringAsFixed(2),
                gradient: [Colors.blue.shade400, Colors.blue.shade200],
              ),
              const SizedBox(width: 12),
              MetricCard(
                icon: Icons.access_time,
                label: 'Peak Hour',
                value: '$peakHour:00',
                gradient: [Colors.purple.shade400, Colors.purple.shade200],
              ),
            ]),
            const SizedBox(height: 20),

            // Line chart card
            ChartContainer(
              child: _buildHourlyLineChart(context, maxCount),
            ),
            const SizedBox(height: 24),

            // Insights
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Insights', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          const TextSpan(text: '• You had '),
                          TextSpan(
                            text: '$maxCount alerts',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: ' at '),
                          TextSpan(
                            text: '$peakHour:00',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: ', which is '),
                          TextSpan(
                            text:
                            '${((maxCount / (avgHourly>0?avgHourly:1)) * 100).round()}% above avg',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (byType.containsKey('Drowsy'))
                      RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium,
                          children: [
                            const TextSpan(text: '• Drowsiness accounted for '),
                            TextSpan(
                              text:
                              '${((byType['Drowsy']! / (totalAlerts>0?totalAlerts:1)) * 100).round()}%',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(text: ' of today’s alerts.'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Filter + Recent
            Text('Filter Issues', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedFilter,
              decoration: InputDecoration(
                labelText: 'Filter Issues',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: filters
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) {
                if (v != null) onFilterChanged(v);
              },
            ),
            const SizedBox(height: 16),
            Text('Recent Issues', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            RecentDetectionsList(
              detections: selectedFilter == 'All'
                  ? recentDetections
                  : recentDetections.where((d) => d.type == selectedFilter).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext c, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHourlyLineChart(BuildContext ctx, int maxCount) {
    final spots = hourlyCounts
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();

    return SizedBox(
      height: 200,
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                backgroundColor: Colors.white, // white plot area
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: max(1, maxCount / 4),
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey[200]!,
                    strokeWidth: 0.8,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 3,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blueAccent,     // blue line
                    barWidth: 3,
                    dotData: FlDotData(
                      show: false,
                      checkToShowDot: (spot, _) => spot.x.toInt() == peakHour,
                      getDotPainter: (_, __, ___, ____) =>
                          FlDotCirclePainter(
                            radius: 6,
                            color: Colors.redAccent,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blueAccent.withOpacity(0.4),
                          Colors.blueAccent.withOpacity(0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                minY: 0,
                maxY: maxCount * 1.2,
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey[200]!),
                ),
              ),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            ),
          ),
        ),
      ),
    );
  }

}
