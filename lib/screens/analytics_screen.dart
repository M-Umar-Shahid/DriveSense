import 'package:flutter/material.dart';
import '../../models/detection.dart';
import '../../services/analytics_service.dart';
import '../components/analytics_screen_components/metrics_section.dart';
import '../components/analytics_screen_components/trend_section.dart';
import '../components/analytics_screen_components/pie_breakdown.dart';
import '../components/analytics_screen_components/recent_detections_list.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});
  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final AnalyticsService _svc = AnalyticsService();
  int _totalAlerts = 0;
  double _totalHours = 0;
  String _recommendation = '';
  List<int> _weeklyCounts = List.filled(7, 0);
  Map<String,int> _monthlyCounts = {};
  List<Detection> _recentDetections = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final rec = await _svc.fetchRecentDetections();
    final weekly = await _svc.fetchWeeklyTrends();
    final monthly = await _svc.fetchMonthlyBreakdown();
    final totals = await _svc.fetchTotals();
    setState(() {
      _recentDetections = rec;
      _weeklyCounts = weekly;
      _monthlyCounts = monthly;
      _totalAlerts = totals['totalAlerts'];
      _totalHours = totals['totalHours'];
      _recommendation = totals['recommendation'];
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
        title: Text('Driving History', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Metrics Section', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              MetricsSection(totalAlerts: _totalAlerts, totalHours: _totalHours, recommendation: _recommendation),
              SizedBox(height: 20),
              Text('Alert Trends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))]
                ),
                padding: EdgeInsets.all(16),
                child: SizedBox(height: 220, child: TrendSection(weeklyCounts: _weeklyCounts)),
              ),
              SizedBox(height: 20),
              Text('Alert Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))]
                ),
                padding: EdgeInsets.all(16),
                child: PieBreakdown(monthlyCounts: _monthlyCounts),
              ),
              SizedBox(height: 20),
              Text('Detected Issues', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              RecentDetectionsList(detections: _recentDetections),
            ],
          ),
        ),
      ),
    );
  }
}
