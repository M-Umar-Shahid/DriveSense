import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 30.0, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 10.0),
                    const Text(
                      "Driving History",
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20.0),

                // Metrics Section
                const Text(
                  "Metrics Section",
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12.0),
                _metricsSection(),

                const SizedBox(height: 20.0),

                // Trend Section
                const Text(
                  "Trend Section",
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12.0),
                _trendSection(),

                const SizedBox(height: 20.0),

                // Detected Issues Section
                const Text(
                  "Detected Issues",
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12.0),
                _detectedIssuesTable(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Metrics Section
  Widget _metricsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _metricTile(Icons.bar_chart, "Total Hours\nMonitored", "1200 Hours"),
          _metricTile(Icons.warning, "Alerts\nGenerated", "45 Alerts"),
          _metricTile(Icons.check_circle, "Recommendation", "Reduce\nDrowsiness"),
        ],
      ),
    );
  }

  Widget _metricTile(IconData icon, String title, String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, size: 30.0, color: Colors.blueAccent),
            const SizedBox(height: 5.0),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 5.0),
            Text(
              value,
              style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Trend Section (Bar Chart)
  Widget _trendSection() {
    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 30),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: _getBottomTitles,
                reservedSize: 20.0,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _getBarGroups(),
        ),
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups() {
    final data = [20, 40, 60, 30, 80, 90, 10];
    return List.generate(
      data.length,
          (index) => BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data[index].toDouble(),
            width: 16,
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(6.0),
          ),
        ],
      ),
    );
  }

  static Widget _getBottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.grey, fontSize: 12.0);
    final titles = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(titles[value.toInt()], style: style),
    );
  }

  // Detected Issues Table
  Widget _detectedIssuesTable() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4.0, offset: Offset(0, 2)),
        ],
        color: Colors.white,
      ),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.blueAccent.withOpacity(0.1)),
        columns: const [
          DataColumn(label: Text("Issue Type", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Timestamp", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Severity", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: List.generate(
          3,
              (index) => const DataRow(
            cells: [
              DataCell(Text("Drowsiness")),
              DataCell(Text("2024-12-12 08:30 AM")),
              DataCell(Text("High", style: TextStyle(color: Colors.redAccent))),
            ],
          ),
        ),
      ),
    );
  }
}
