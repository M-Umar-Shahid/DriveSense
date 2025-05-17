import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../models/detection.dart';
import '../../models/trip.dart';
import '../../services/analytics_service.dart';
import '../components/analytics_screen_components/metrics_section.dart';
import '../components/analytics_screen_components/trend_section.dart';
import '../components/analytics_screen_components/pie_breakdown.dart';
import '../components/analytics_screen_components/recent_detections_list.dart';

class AnalyticsPage extends StatefulWidget {
  final String driverId;
  const AnalyticsPage({Key? key, required this.driverId}) : super(key: key);

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with TickerProviderStateMixin {
  final _svc = AnalyticsService();

  bool _loading = true;
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
    // fetch everything in parallel
    final rec     = _svc.fetchRecentDetections(widget.driverId, limit: 5);
    final weekly  = _svc.fetchWeeklyTrends(widget.driverId);
    final monthly = _svc.fetchMonthlyBreakdown(widget.driverId);
    final totals  = _svc.fetchTotals(widget.driverId);

    final results = await Future.wait([rec, weekly, monthly, totals]);
    if (!mounted) return;

    setState(() {
      _recentDetections  = results[0] as List<Detection>;
      _weeklyCounts      = results[1] as List<int>;
      _monthlyCounts     = results[2] as Map<String,int>;
      final totMap       = results[3] as Map<String, dynamic>;
      _totalAlerts       = totMap['totalAlerts'];
      _totalHours        = totMap['totalHours'];
      _recommendation    = totMap['recommendation'];
      _loading           = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // loading state
    if (_loading) {
      return Scaffold(
        body: Center(
          child: Lottie.asset(
            'assets/animations/loading_animation.json',
            width: 180,
            height: 180,
            repeat: true,
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.orangeAccent,
          elevation: 0,
          centerTitle: true,
          title: const Text('Analytics',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Day'),
              Tab(text: 'Week'),
              Tab(text: 'Month'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDayView(),
            _buildWeekView(),
            _buildMonthView(),
          ],
        ),
      ),
    );
  }

  Widget _buildDayView() {
    // You can swap this with today’s specific data
    return _buildCommonBody(
      title: 'Today\'s Trend',
      trendWidget: Center(child: Text(
        '${_weeklyCounts[DateTime.now().weekday % 7]} alerts today',
        style: const TextStyle(fontSize: 18),
      )),
    );
  }

  Widget _buildWeekView() {
    return _buildCommonBody(
      title: 'Weekly Trend',
      trendWidget: TrendSection(weeklyCounts: _weeklyCounts),
    );
  }

  Widget _buildMonthView() {
    return _buildCommonBody(
      title: 'Monthly Breakdown',
      trendWidget: PieBreakdown(monthlyCounts: _monthlyCounts),
    );
  }

  Widget _buildCommonBody({required String title, required Widget trendWidget}) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metrics
            const Text('Metrics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            MetricsSection(
              totalAlerts: _totalAlerts,
              totalHours: _totalHours,
              recommendation: _recommendation,
            ),

            const SizedBox(height: 24),

            // Trend / Chart
            Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0,4))],
              ),
              padding: const EdgeInsets.all(16),
              child: trendWidget,
            ),

            const SizedBox(height: 24),

            // Recent Issues
            const Text('Recent Issues',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            RecentDetectionsList(detections: _recentDetections),
          ],
        ),
      ),
    );
  }
}
