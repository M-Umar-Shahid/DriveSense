import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';

import '../../models/detection.dart';
import '../../services/analytics_service.dart';
import '../components/analytics_screen_components/build_manual_heatmap.dart';
import '../components/analytics_screen_components/metrics_section.dart';
import '../components/analytics_screen_components/month_picker.dart';
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
  bool _loadingMonth = true;

  int _totalAlerts = 0;
  double _totalHours = 0;
  String _recommendation = '';
  List<int> _weeklyCounts = List.filled(7, 0);
  List<int> _hourlyCounts = List.filled(24, 0);
  List<Detection> _recentDetections = [];

  Map<String, int> _monthlyCounts = {};
  Map<DateTime, int> _last30Days = {};

  double _alertsDelta = 0;
  double _hoursDelta = 0;

  DateTime _currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAll();
    _loadForMonth(_currentMonth);
  }

  Future<void> _loadAll() async {
    try {
      final rec = _svc.fetchRecentDetections(widget.driverId, limit: 5);
      final weekly = _svc.fetchWeeklyTrends(widget.driverId);
      final totals = _svc.fetchTotals(widget.driverId);
      final hourly = _svc.fetchHourlyCounts(widget.driverId);
      final heatmap = _svc.fetchLast30DaysCounts(widget.driverId);

      final results = await Future.wait([rec, weekly, totals, hourly, heatmap]);
      if (!mounted) return;

      final totMap = results[2] as Map<String, dynamic>;
      setState(() {
        _recentDetections = results[0] as List<Detection>;
        _weeklyCounts = results[1] as List<int>;

        _totalAlerts = (totMap['totalAlerts'] as int?) ?? 0;
        _totalHours = (totMap['totalHours'] as num?)?.toDouble() ?? 0.0;
        _recommendation = (totMap['recommendation'] as String?) ?? '';
        _alertsDelta = (totMap['alertsDelta'] as num?)?.toDouble() ?? 0.0;
        _hoursDelta = (totMap['hoursDelta'] as num?)?.toDouble() ?? 0.0;

        _hourlyCounts = results[3] as List<int>;
        _last30Days = results[4] as Map<DateTime, int>;

        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadForMonth(DateTime month) async {
    setState(() => _loadingMonth = true);
    try {
      final m = await _svc.fetchMonthlyBreakdownForMonth(widget.driverId, month);
      final h = await _svc.fetchDailyCountsForMonth(widget.driverId, month);
      if (!mounted) return;
      setState(() {
        _monthlyCounts = m;
        _last30Days = h;
        _loadingMonth = false;
      });
    } catch (e) {
      debugPrint('Error loading month data: $e');
      if (!mounted) return;
      setState(() => _loadingMonth = false);
    }
  }

  void _changeMonth(int offset) {
    final next = DateTime(_currentMonth.year, _currentMonth.month + offset, 1);
    setState(() => _currentMonth = next);
    _loadForMonth(next);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Lottie.asset(
            'assets/animations/loading_animation.json',
            width: 180,
            height: 180,
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.blueAccent,
          centerTitle: true,
          elevation: 0,
          title: const Text(
            'Analytics',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [Tab(text: 'Day'), Tab(text: 'Week'), Tab(text: 'Month')],
          ),
        ),
        body: TabBarView(
          children: [_buildDayView(), _buildWeekView(), _buildMonthView()],
        ),
      ),
    );
  }

  Widget _buildDayView() => _buildCommonBody(
    title: 'Hourly Trend',
    trendWidget: TrendSection(
      counts: _hourlyCounts,
      isSparkline: true,
      showXAxis: true,
    ),
  );

  Widget _buildWeekView() => _buildCommonBody(
    title: 'Weekly Trend',
    trendWidget: TrendSection(counts: _weeklyCounts),
  );

  Widget _buildMonthView() => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Monthly Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          MonthPicker(
            month: DateFormat.yMMM().format(_currentMonth),
            onPrev: () => _changeMonth(-1),
            onNext: () => _changeMonth(1),
          ),
          const SizedBox(height: 16),

          Card(
            color: Colors.grey.shade50,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _loadingMonth
                  ? SizedBox(
                height: 250,
                child: Center(
                  child: Lottie.asset(
                    'assets/animations/loading_animation.json',
                    width: 80,
                    height: 80,
                  ),
                ),
              )
                  : Column(
                children: [
                  PieBreakdown(
                    data: _monthlyCounts,
                    showLegend: true,
                  ),
                  const SizedBox(height: 24),
                  buildManualHeatmap(
                    data: _last30Days,
                    month: _currentMonth,
                    size: 20,
                    baseColor: Colors.green,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildCommonBody({required String title, required Widget trendWidget}) =>
      SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Metrics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              MetricsSection(
                totalAlerts: _totalAlerts,
                totalHours: _totalHours,
                recommendation: _recommendation,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _kpiCard(
                      'Alerts',
                      _formatDelta(_alertsDelta),
                      _alertsDelta >= 0 ? Icons.trending_up : Icons.trending_down,
                      _alertsDelta >= 0 ? Colors.green : Colors.redAccent),
                  _kpiCard(
                      'Hours',
                      _formatDelta(_hoursDelta),
                      _hoursDelta >= 0 ? Icons.trending_up : Icons.trending_down,
                      _hoursDelta >= 0 ? Colors.green : Colors.redAccent),
                ],
              ),
              const SizedBox(height: 24),
              Text(title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                ),
                padding: const EdgeInsets.all(16),
                child: trendWidget,
              ),
              const SizedBox(height: 24),
              const Text('Recent Issues',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              RecentDetectionsList(detections: _recentDetections),
            ],
          ),
        ),
      );

  Widget _kpiCard(String label, String delta, IconData icon, Color color) =>
      Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(delta,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      );

  String _formatDelta(double val) =>
      val >= 0 ? '+${val.toStringAsFixed(1)}%' : '${val.toStringAsFixed(1)}%';
}
