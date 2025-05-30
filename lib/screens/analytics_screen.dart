// lib/screens/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
<<<<<<< Updated upstream
<<<<<<< Updated upstream
import 'package:calendar_heatmap/calendar_heatmap.dart';
=======
=======
>>>>>>> Stashed changes
<<<<<<< HEAD
import 'package:intl/intl.dart';

=======
import 'package:calendar_heatmap/calendar_heatmap.dart';
>>>>>>> 16548fd9f372664a8405d77e23307aa5fba1743b
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
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

  // global loader (initial page load)
  bool _loading = true;

  // month‐only loader
  bool _loadingMonth = true;

  // data fields
  int _totalAlerts = 0;
  double _totalHours = 0;
  String _recommendation = '';
  List<int> _weeklyCounts = List.filled(7, 0);
<<<<<<< Updated upstream
<<<<<<< Updated upstream
  Map<String, int> _monthlyCounts = {};
=======
=======
>>>>>>> Stashed changes
<<<<<<< HEAD
  List<int> _hourlyCounts = List.filled(24, 0);
=======
  Map<String, int> _monthlyCounts = {};
>>>>>>> 16548fd9f372664a8405d77e23307aa5fba1743b
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
  List<Detection> _recentDetections = [];
  List<int> _hourlyCounts = List.filled(24, 0);
  Map<DateTime, int> _last30Days = {};
  double _alertsDelta = 0;
  double _hoursDelta = 0;
<<<<<<< Updated upstream
<<<<<<< Updated upstream
=======
=======
>>>>>>> Stashed changes

  Map<String, int> _monthlyCounts = {};
  Map<DateTime, int> _last30Days = {};

  double _alertsDelta = 0;
  double _hoursDelta = 0;

  // month navigation state
  DateTime _currentMonth = DateTime.now();
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes

  @override
  void initState() {
    super.initState();
    _loadAll();                            // initial everything
    _loadForMonth(_currentMonth);          // initial month view
  }

  // ─── DATA LOADERS ───────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
<<<<<<< Updated upstream
<<<<<<< Updated upstream
    final rec       = _svc.fetchRecentDetections(widget.driverId, limit: 5);
    final weekly    = _svc.fetchWeeklyTrends(widget.driverId);
    final monthly   = _svc.fetchMonthlyBreakdown(widget.driverId);
    final totals    = _svc.fetchTotals(widget.driverId);
    final hourly    = _svc.fetchHourlyCounts(widget.driverId);
    final heatmap   = _svc.fetchLast30DaysCounts(widget.driverId);

=======
<<<<<<< HEAD
    try {
      final rec     = _svc.fetchRecentDetections(widget.driverId, limit: 5);
      final weekly  = _svc.fetchWeeklyTrends(widget.driverId);
      final totals  = _svc.fetchTotals(widget.driverId);
      final hourly  = _svc.fetchHourlyCounts(widget.driverId);
      final heatmap = _svc.fetchLast30DaysCounts(widget.driverId);

=======
<<<<<<< HEAD
    try {
      final rec     = _svc.fetchRecentDetections(widget.driverId, limit: 5);
      final weekly  = _svc.fetchWeeklyTrends(widget.driverId);
      final totals  = _svc.fetchTotals(widget.driverId);
      final hourly  = _svc.fetchHourlyCounts(widget.driverId);
      final heatmap = _svc.fetchLast30DaysCounts(widget.driverId);

>>>>>>> Stashed changes
      final results = await Future.wait([rec, weekly, totals, hourly, heatmap]);


      final totMap = results[3] as Map<String, dynamic>;

      setState(() {
        _recentDetections = results[0] as List<Detection>;
        _weeklyCounts     = results[1] as List<int>;
        // results[2] is now totals, so shift everything down by one:
        final totMap      = results[2] as Map<String,dynamic>;
        _totalAlerts      = (totMap['totalAlerts'] as int?) ?? 0;
        // … etc …
        _hourlyCounts     = results[3] as List<int>;
        _last30Days       = results[4] as Map<DateTime,int>;
        _loading          = false;
      });
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
=======
    final rec       = _svc.fetchRecentDetections(widget.driverId, limit: 5);
    final weekly    = _svc.fetchWeeklyTrends(widget.driverId);
    final monthly   = _svc.fetchMonthlyBreakdown(widget.driverId);
    final totals    = _svc.fetchTotals(widget.driverId);
    final hourly    = _svc.fetchHourlyCounts(widget.driverId);
    final heatmap   = _svc.fetchLast30DaysCounts(widget.driverId);

<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
    final results = await Future.wait([rec, weekly, monthly, totals, hourly, heatmap]);
    if (!mounted) return;

    final totMap = results[3] as Map<String, dynamic>;
    setState(() {
      _recentDetections = results[0] as List<Detection>;
      _weeklyCounts     = results[1] as List<int>;
      _monthlyCounts    = results[2] as Map<String, int>;
      _totalAlerts      = totMap['totalAlerts'];
      _totalHours       = totMap['totalHours'];
      _recommendation   = totMap['recommendation'];
      _alertsDelta      = totMap['alertsDelta'];
      _hoursDelta       = totMap['hoursDelta'];
      _hourlyCounts     = results[4] as List<int>;
      _last30Days       = results[5] as Map<DateTime, int>;
      _loading          = false;
    });
>>>>>>> 16548fd9f372664a8405d77e23307aa5fba1743b
  }

  Future<void> _loadForMonth(DateTime month) async {
    setState(() => _loadingMonth = true);
    try {
      final m = await _svc.fetchMonthlyBreakdownForMonth(widget.driverId, month);
      final h = await _svc.fetchDailyCountsForMonth(widget.driverId, month);
      if (!mounted) return;
      setState(() {
        _monthlyCounts = m;
        _last30Days    = h;
        _loadingMonth  = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMonth = false);
    }
  }

  // ─── MONTH NAVIGATION ────────────────────────────────────────────────────────

  void _changeMonth(int offset) {
    final next = DateTime(_currentMonth.year, _currentMonth.month + offset, 1);
    setState(() => _currentMonth = next);
    _loadForMonth(next);
  }

  // ─── BUILD ──────────────────────────────────────────────────────────────────

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
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Analytics',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
<<<<<<< Updated upstream
<<<<<<< Updated upstream
=======
<<<<<<< HEAD
=======
>>>>>>> Stashed changes
=======
<<<<<<< HEAD
=======
>>>>>>> Stashed changes
          actions: [ // date-range picker
            IconButton(
              icon: const Icon(Icons.date_range),
              onPressed: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (range != null) {
                  // implement _loadForRange
                }
              },
            ),
          ],
<<<<<<< Updated upstream
<<<<<<< Updated upstream
=======
>>>>>>> 16548fd9f372664a8405d77e23307aa5fba1743b
>>>>>>> Stashed changes
=======
>>>>>>> 16548fd9f372664a8405d77e23307aa5fba1743b
>>>>>>> Stashed changes
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
<<<<<<< Updated upstream
<<<<<<< Updated upstream
=======
=======
>>>>>>> Stashed changes
<<<<<<< HEAD
              Tab(text: 'Day'),
              Tab(text: 'Week'),
              Tab(text: 'Month'),
=======
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
              Tab(child: Text('Day', style: TextStyle(color: Colors.white))),
              Tab(child: Text('Week', style: TextStyle(color: Colors.white))),
              Tab(child: Text('Month', style: TextStyle(color: Colors.white))),
>>>>>>> 16548fd9f372664a8405d77e23307aa5fba1743b
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildDayView(), _buildWeekView(), _buildMonthView()],
        ),
      ),
    );
  }

  Widget _buildDayView() {
    return _buildCommonBody(
<<<<<<< Updated upstream
<<<<<<< Updated upstream
=======
=======
>>>>>>> Stashed changes
<<<<<<< HEAD
      title: 'Hourly Trend',
      trendWidget: TrendSection(
        counts: _hourlyCounts,
        isSparkline: true,
        showXAxis: true,
      ),
    );
=======
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
              title: 'Hourly Trend',
              trendWidget: TrendSection(
                counts: _hourlyCounts,
                isSparkline: true,
                showXAxis: true,
              ),
        );
<<<<<<< Updated upstream
<<<<<<< Updated upstream
=======
>>>>>>> 16548fd9f372664a8405d77e23307aa5fba1743b
>>>>>>> Stashed changes
=======
>>>>>>> 16548fd9f372664a8405d77e23307aa5fba1743b
>>>>>>> Stashed changes
  }

  Widget _buildWeekView() {
    return _buildCommonBody(
<<<<<<< Updated upstream
<<<<<<< Updated upstream
=======
=======
>>>>>>> Stashed changes
<<<<<<< HEAD
      title: 'Weekly Trend',
      trendWidget: TrendSection(counts: _weeklyCounts),
    );
=======
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
              title: 'Weekly Trend',
              trendWidget: TrendSection(
                counts: _weeklyCounts,
              ),
        );
<<<<<<< Updated upstream
<<<<<<< Updated upstream
=======
>>>>>>> 16548fd9f372664a8405d77e23307aa5fba1743b
>>>>>>> Stashed changes
=======
>>>>>>> 16548fd9f372664a8405d77e23307aa5fba1743b
>>>>>>> Stashed changes
  }
  Widget _buildMonthView() {
<<<<<<< HEAD
=======
    return _buildCommonBody(
      title: 'Monthly Breakdown',
      trendWidget: Column(
        children: [
          PieBreakdown(data: _monthlyCounts, showLegend: true),
          const SizedBox(height: 24),
          const Text('30-Day Alert Heatmap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          CalendarHeatMap(
            input: _last30Days,
            colorThresholds: {
              1: Colors.blue[100]!,
              5: Colors.blue[300]!,
              10: Colors.blue[600]!,
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommonBody({required String title, required Widget trendWidget}) {
>>>>>>> 16548fd9f372664a8405d77e23307aa5fba1743b
<<<<<<< Updated upstream
=======
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
<<<<<<< HEAD
            const Text('Monthly Breakdown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // ── Month selector ────────────────────
            MonthPicker(
              month: DateFormat.yMMM().format(_currentMonth),
              onPrev: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
            ),
            const SizedBox(height: 16),

            // ── Charts container ──────────────────
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _loadingMonth
                // small spinner for the month section only
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
                // once loaded, show pie + heatmap
                    : Column(
                  children: [
                    // ─ Pie chart ─────────────────
                    PieBreakdown(
                      data: _monthlyCounts,
                      showLegend: true,
                    ),
                    const SizedBox(height: 24),

                    // ─ Heatmap ───────────────────────
                    // instead of package widget…
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
  }

  Widget _buildCommonBody({
    required String title,
    required Widget trendWidget,
  }) {
>>>>>>> Stashed changes
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
<<<<<<< Updated upstream
<<<<<<< HEAD
            const Text('Monthly Breakdown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // ── Month selector ────────────────────
            MonthPicker(
              month: DateFormat.yMMM().format(_currentMonth),
              onPrev: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
            ),
            const SizedBox(height: 16),

            // ── Charts container ──────────────────
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _loadingMonth
                // small spinner for the month section only
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
                // once loaded, show pie + heatmap
                    : Column(
                  children: [
                    // ─ Pie chart ─────────────────
                    PieBreakdown(
                      data: _monthlyCounts,
                      showLegend: true,
                    ),
                    const SizedBox(height: 24),

                    // ─ Heatmap ───────────────────────
                    // instead of package widget…
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
  }

  Widget _buildCommonBody({
    required String title,
    required Widget trendWidget,
  }) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
<<<<<<< Updated upstream
            const Text('Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
=======
=======
>>>>>>> Stashed changes
            const Text('Metrics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
=======
            const Text('Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
>>>>>>> 16548fd9f372664a8405d77e23307aa5fba1743b
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
            const SizedBox(height: 8),
            MetricsSection(
              totalAlerts: _totalAlerts,
              totalHours: _totalHours,
              recommendation: _recommendation,
            ),
            const SizedBox(height: 12),
            Row(
<<<<<<< Updated upstream
<<<<<<< Updated upstream
=======
=======
>>>>>>> Stashed changes
<<<<<<< HEAD
              children: [
                Expanded(
                  child: _kpiCard(
                    'Alerts',
                    _formatDelta(_alertsDelta),
                    _alertsDelta >= 0
                        ? Icons.trending_up
                        : Icons.trending_down,
                    _alertsDelta >= 0 ? Colors.green : Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _kpiCard(
                    'Hours',
                    _formatDelta(_hoursDelta),
                    _hoursDelta >= 0
                        ? Icons.trending_up
                        : Icons.trending_down,
                    _hoursDelta >= 0 ? Colors.green : Colors.redAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(title,
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
=======
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _kpiCard('Alerts', _formatDelta(_alertsDelta), _alertsDelta >= 0 ? Icons.trending_up : Icons.trending_down, _alertsDelta >= 0 ? Colors.green : Colors.redAccent),
                _kpiCard('Hours', _formatDelta(_hoursDelta), _hoursDelta >= 0 ? Icons.trending_up : Icons.trending_down, _hoursDelta >= 0 ? Colors.green : Colors.redAccent),
              ],
            ),
            const SizedBox(height: 24),

            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
<<<<<<< Updated upstream
<<<<<<< Updated upstream
=======
>>>>>>> 16548fd9f372664a8405d77e23307aa5fba1743b
>>>>>>> Stashed changes
=======
>>>>>>> 16548fd9f372664a8405d77e23307aa5fba1743b
>>>>>>> Stashed changes
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
<<<<<<< Updated upstream
<<<<<<< Updated upstream
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))],
=======
=======
>>>>>>> Stashed changes
<<<<<<< HEAD
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
=======
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))],
>>>>>>> 16548fd9f372664a8405d77e23307aa5fba1743b
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
              ),
              padding: const EdgeInsets.all(16),
              child: trendWidget,
            ),
            const SizedBox(height: 24),
<<<<<<< Updated upstream
<<<<<<< Updated upstream
            const Text('Recent Issues', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
=======
=======
>>>>>>> Stashed changes
<<<<<<< HEAD
            const Text('Recent Issues',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
=======
            const Text('Recent Issues', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
>>>>>>> 16548fd9f372664a8405d77e23307aa5fba1743b
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
            const SizedBox(height: 8),
            RecentDetectionsList(detections: _recentDetections),
          ],
        ),
      ),
    );
  }

<<<<<<< Updated upstream
<<<<<<< Updated upstream
=======
=======
>>>>>>> Stashed changes
<<<<<<< HEAD
  Widget _kpiCard(
      String label, String delta, IconData icon, Color color) {
    return Container(
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
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  String _formatDelta(double val) =>
      val >= 0 ? '+${val.toStringAsFixed(1)}%' : '${val.toStringAsFixed(1)}%';
}
=======
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
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
              Text(delta, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      );

  String _formatDelta(double val) => val >= 0 ? '+${val.toStringAsFixed(1)}%' : '${val.toStringAsFixed(1)}%';
<<<<<<< Updated upstream
<<<<<<< Updated upstream
}
=======
}
>>>>>>> 16548fd9f372664a8405d77e23307aa5fba1743b
>>>>>>> Stashed changes
=======
}
>>>>>>> 16548fd9f372664a8405d77e23307aa5fba1743b
>>>>>>> Stashed changes
