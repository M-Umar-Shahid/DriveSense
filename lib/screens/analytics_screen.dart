import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/detection.dart';
import '../../services/analytics_service.dart';
import '../components/analytics_screen_components/build_manual_heatmap.dart';
import '../components/analytics_screen_components/day_analytics_view.dart';
import '../components/analytics_screen_components/metric_card.dart';
import '../components/analytics_screen_components/metrics_section.dart';
import '../components/analytics_screen_components/month_picker.dart';
import '../components/analytics_screen_components/pie_breakdown.dart';
import '../components/analytics_screen_components/recent_detections_list.dart';

class AnalyticsPage extends StatefulWidget {
  final String driverId;
  const AnalyticsPage({Key? key, required this.driverId}) : super(key: key);

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final _svc = AnalyticsService();

  // Loading flags
  bool _loading = true, _loadingMonth = true;

  // Raw data
  List<Detection> _recentDetections = [];
  List<int> _hourlyCounts = List.filled(24, 0);
  List<int> _weeklyCounts = List.filled(7, 0);
  Map<String,int> _monthlyCounts = {};
  Map<DateTime,int> _last30Days = {};

  // Computed
  int _peakHour = 0, _totalAlerts = 0;
  double _avgHourlyAlerts = 0;
  double _avgDailyAlerts = 0;
  int _peakWeekDay = 0;

  // Tabs state
  bool _showComparison = false;
  String _selectedFilter = 'All';
  final _filters = ['All', 'Drowsy', 'No Seatbelt', 'Yawning'];
  DateTime _currentMonth = DateTime.now();
  final _weekDays = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];

  @override
  void initState() {
    super.initState();
    _loadAll();
    _loadForMonth(_currentMonth);
  }

  Future<void> _loadAll() async {
    try {
      final results = await Future.wait([
        _svc.fetchRecentDetections(widget.driverId, limit: 10),
        _svc.fetchHourlyCounts(widget.driverId),
        _svc.fetchWeeklyTrends(widget.driverId),
        _svc.fetchTotals(widget.driverId),
      ]);

      final recList   = results[0] as List<Detection>;
      final hours     = results[1] as List<int>;
      final week      = results[2] as List<int>;
      final totalsMap = results[3] as Map<String, dynamic>;

      setState(() {
        _recentDetections = recList;
        _hourlyCounts     = hours;
        _weeklyCounts     = week;

        _totalAlerts       = totalsMap['totalAlerts'] as int;
        _avgHourlyAlerts   = hours.isNotEmpty
            ? hours.reduce((a,b) => a+b) / hours.length
            : 0.0;
        _peakHour = hours.asMap()
            .entries
            .reduce((a,b) => b.value > a.value ? b : a)
            .key;

        _avgDailyAlerts = week.isNotEmpty
            ? week.reduce((a,b) => a+b) / week.length
            : 0.0;
        _peakWeekDay = week.asMap()
            .entries
            .reduce((a,b) => b.value > a.value ? b : a)
            .key;

        _loading = false;
      });
    } catch (e) {
      debugPrint('Analytics load error: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadForMonth(DateTime month) async {
    setState(() => _loadingMonth = true);
    try {
      final pieData = await _svc.fetchMonthlyBreakdownForMonth(widget.driverId, month);
      final heat   = await _svc.fetchDailyCountsForMonth(widget.driverId, month);
      setState(() {
        _monthlyCounts = pieData;
        _last30Days    = heat;
        _loadingMonth  = false;
      });
    } catch (e) {
      debugPrint('Month load error: $e');
      setState(() => _loadingMonth = false);
    }
  }

  void _changeMonth(int offset) {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset, 1);
    _loadForMonth(_currentMonth);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Lottie.asset('assets/animations/loading_animation.json', width: 180)),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.blueAccent,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white)),
          bottom: TabBar(
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(width: 3, color: Colors.white),
              insets: EdgeInsets.symmetric(horizontal: 32),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Day'),
              Tab(text: 'Week'),
              Tab(text: 'Month'),
            ],
          ),

        ),
        body: TabBarView(
          children: [
            _buildDayTab(),
            _buildWeekTab(),
            _buildMonthTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildDayTab() {
    return DayAnalyticsView(
      showComparison: _showComparison,
      onComparisonChanged: (val) => setState(() => _showComparison = val),
      avgHourly: _avgHourlyAlerts,
      peakHour: _peakHour,
      hourlyCounts: _hourlyCounts,
      recentDetections: _recentDetections,
      selectedFilter: _selectedFilter,
      filters: _filters,
      onFilterChanged: (f) => setState(() => _selectedFilter = f),
    );
  }

  Widget _buildWeekTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weekly Trend', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            // Use your existing metrics_section or gradient cards here…
          Row(
                          children: [
                        Expanded(
                          child: MetricCard(
                            icon: Icons.show_chart,
                                label: 'Avg / day',
                                value: _avgDailyAlerts.toStringAsFixed(2),
                            gradient: [Colors.green.shade400, Colors.green.shade200],
                          ),
                      ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      icon: Icons.calendar_today,
                      label: 'Peak Day',
                      value: _weekDays[_peakWeekDay],
                      gradient: [Colors.orange.shade400, Colors.orange.shade200],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            buildChartContainer(child: _buildLineChart(
              spots: _weeklyCounts.asMap().entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                  .toList(),
              color: Colors.green,
              labels: _weekDays,
            )),
            const SizedBox(height: 24),
            Text('Recent Issues', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            RecentDetectionsList(detections: _recentDetections),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monthly Breakdown', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            MonthPicker(
              month: DateFormat.yMMM().format(_currentMonth),
              onPrev: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _loadingMonth
                    ? SizedBox(height: 200, child: Center(child: Lottie.asset('assets/animations/loading_animation.json', width: 80)))
                    : Column(
                  children: [
                    PieBreakdown(data: _monthlyCounts, showLegend: true),
                    const SizedBox(height: 24),
                    buildManualHeatmap(
                      data: _last30Days,
                      month: _currentMonth,
                      size: 20,
                      baseColor: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for week chart
  Widget buildChartContainer({required Widget child}) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
    ),
    padding: const EdgeInsets.all(16),
    child: child,
  );

  Widget _buildLineChart({
    required List<FlSpot> spots,
    required Color color,
    required List<String> labels,
  }) {
    final maxY = spots.map((s) => s.y).fold(0.0, max) * 1.2;
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false,
            horizontalInterval: max(1, maxY/4),
            getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey[200]!, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1,
              getTitlesWidget: (v,_) => Text(labels[v.toInt()], style: const TextStyle(fontSize: 10)),
            )),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.4), color.withOpacity(0.05)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          minY: 0,
          maxY: maxY,
          borderData: FlBorderData(show: false),
        ),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      ),
    );
  }
}
