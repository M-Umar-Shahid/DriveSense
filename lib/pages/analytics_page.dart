import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  int _totalAlerts = 0;
  double _totalHours = 0;
  String _recommendation = "Analyzing...";
  List<int> _weeklyAlertCounts = List.filled(7, 0);
  Map<String, int> _monthlyAlertTypeCounts = {};

  @override
  void initState() {
    super.initState();
    _fetchMetrics();
    _fetchWeeklyTrends();
    _fetchMonthlyAlertBreakdown();
    _fetchRecentDetections();
  }

  List<Map<String, dynamic>> _recentDetections = [];

  Future<void> _fetchRecentDetections() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('detections')
        .where('uid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(5)
        .get();

    final List<Map<String, dynamic>> recent = snapshot.docs.map((doc) {
      return {
        'type': doc['alertType'] ?? 'Unknown',
        'timestamp': (doc['timestamp'] as Timestamp).toDate(),
        'severity': _getSeverity(doc['alertType']),
      };
    }).toList();

    setState(() {
      _recentDetections = recent;
    });
  }

  String _getSeverity(String type) {
    if (type == 'Drowsy' || type == 'Distraction') return 'High';
    if (type == 'Yawning') return 'Medium';
    return 'Low';
  }


  Future<void> _fetchMonthlyAlertBreakdown() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final snapshot = await FirebaseFirestore.instance
        .collection('detections')
        .where('uid', isEqualTo: uid)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .get();

    final Map<String, int> counts = {};
    for (var doc in snapshot.docs) {
      final alertType = doc['alertType'] ?? 'Unknown';
      counts[alertType] = (counts[alertType] ?? 0) + 1;
    }

    setState(() {
      _monthlyAlertTypeCounts = counts;
    });
  }

  List<PieChartSectionData> _buildPieSections() {
    final total = _monthlyAlertTypeCounts.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey[300],
          value: 1,
          showTitle: false,
        ),
      ];
    }

    final colors = [
      Colors.orangeAccent,
      Colors.deepPurpleAccent,
      Colors.green,
      Colors.pinkAccent,
      Colors.indigo,
      Colors.teal,
      Colors.cyan,
    ];

    final keys = _monthlyAlertTypeCounts.keys.toList();
    return List.generate(keys.length, (i) {
      final key = keys[i];
      final value = _monthlyAlertTypeCounts[key]!.toDouble();
      final percent = (value / total) * 100;
      return PieChartSectionData(
        color: colors[i % colors.length],
        value: value,
        title: percent < 5 ? '' : '${percent.toStringAsFixed(1)}%',
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        radius: 40,
      );
    });
  }

  Widget _buildPieLegend() {
    final keys = _monthlyAlertTypeCounts.keys.toList();
    final colors = [
      Colors.orangeAccent,
      Colors.deepPurpleAccent,
      Colors.green,
      Colors.pinkAccent,
      Colors.indigo,
      Colors.teal,
      Colors.cyan,
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: List.generate(keys.length, (i) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[i % colors.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(keys[i], style: const TextStyle(fontSize: 12)),
          ],
        );
      }),
    );
  }

  Future<void> _fetchMetrics() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final alertsSnap = await FirebaseFirestore.instance
        .collection('detections')
        .where('uid', isEqualTo: uid)
        .get();

    final tripsSnap = await FirebaseFirestore.instance
        .collection('trips')
        .where('uid', isEqualTo: uid)
        .get();

    int totalAlerts = alertsSnap.size;
    double totalHours = 0;
    Map<String, int> alertTypeCount = {};

    for (var doc in tripsSnap.docs) {
      final start = (doc['startTime'] as Timestamp).toDate();
      final end = doc.data().containsKey('endTime') ? (doc['endTime'] as Timestamp?)?.toDate() : null;
      if (end != null) {
        totalHours += end.difference(start).inMinutes / 60.0;
      }
    }

    for (var doc in alertsSnap.docs) {
      final type = doc['alertType'] ?? 'Unknown';
      alertTypeCount[type] = (alertTypeCount[type] ?? 0) + 1;
    }

    final mostFrequent = alertTypeCount.entries.fold<MapEntry<String, int>>(
      MapEntry('', 0),
          (prev, curr) => curr.value > prev.value ? curr : prev,
    );

    setState(() {
      _totalAlerts = totalAlerts;
      _totalHours = totalHours;
      _recommendation = mostFrequent.key == 'Drowsy'
          ? 'Avoid drowsy driving'
          : mostFrequent.key == 'Yawning'
          ? 'Stay hydrated and rested'
          : mostFrequent.key == 'Distraction'
          ? 'Keep focus on the road'
          : 'Keep up the safe driving!';
    });
  }

  Future<void> _fetchWeeklyTrends() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));

    final snapshot = await FirebaseFirestore.instance
        .collection('detections')
        .where('uid', isEqualTo: uid)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
        .get();

    List<int> counts = List.filled(7, 0);

    for (var doc in snapshot.docs) {
      final timestamp = (doc['timestamp'] as Timestamp).toDate();
      int dayIndex = timestamp.weekday % 7; // 0 = Sunday
      counts[dayIndex]++;
    }

    setState(() {
      _weeklyAlertCounts = counts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text("Driving History", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Metrics Section", style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12.0),
                _metricsSection(),

                const SizedBox(height: 20.0),
                const Text("Alert Trends", style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12.0),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 220,
                    child: _trendSection(),
                  ),
                ),

                const SizedBox(height: 20.0),
                const Text("Alert Breakdown", style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12.0),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPieLegend(),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: _buildPieSections(),
                            sectionsSpace: 4,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20.0),
                const Text("Detected Issues", style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12.0),
                _recentDetections.isEmpty
                    ? const Text("No alerts recorded this month.")
                    : Column(
                  children: _recentDetections.map((issue) {
                    final timestamp = DateFormat('MMM d, yyyy – hh:mm a').format(issue['timestamp']);
                    final severityColor = issue['severity'] == 'High'
                        ? Colors.redAccent
                        : issue['severity'] == 'Medium'
                        ? Colors.orangeAccent
                        : Colors.green;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: severityColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(issue['type'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(timestamp, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          Chip(
                            label: Text(issue['severity']),
                            backgroundColor: severityColor.withOpacity(0.1),
                            labelStyle: TextStyle(color: severityColor),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metricsSection() {
    return Column(
      children: [
        _metricCard(Icons.av_timer, "Total Hours Monitored", "${_totalHours.toStringAsFixed(1)} hrs", Colors.deepPurple),
        _metricCard(Icons.warning_amber_rounded, "Alerts Generated", "$_totalAlerts Alerts", Colors.orange),
        _metricCard(Icons.lightbulb, "Recommendation", _recommendation, Colors.teal),
      ],
    );
  }

  Widget _metricCard(IconData icon, String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendSection() {
    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(enabled: true),
        gridData: const FlGridData(show: true),
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
        barGroups: List.generate(
          7,
              (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: _weeklyAlertCounts[index].toDouble(),
                width: 20,
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(8.0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _getBottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.grey, fontSize: 12.0);
    const titles = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(titles[value.toInt()], style: style),
    );
  }
}