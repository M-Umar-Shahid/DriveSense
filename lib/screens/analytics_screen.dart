import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:calendar_heatmap/calendar_heatmap.dart';
import '../../models/detection.dart';
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
  Map<String, int> _monthlyCounts = {};
  List<Detection> _recentDetections = [];
  List<int> _hourlyCounts = List.filled(24, 0);
  Map<DateTime, int> _last30Days = {};
  double _alertsDelta = 0;
  double _hoursDelta = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final rec       = _svc.fetchRecentDetections(widget.driverId, limit: 5);
    final weekly    = _svc.fetchWeeklyTrends(widget.driverId);
    final monthly   = _svc.fetchMonthlyBreakdown(widget.driverId);
    final totals    = _svc.fetchTotals(widget.driverId);
    final hourly    = _svc.fetchHourlyCounts(widget.driverId);
    final heatmap   = _svc.fetchLast30DaysCounts(widget.driverId);

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
            repeat: true,
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
          bottom: const TabBar(
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blueAccent,
            tabs: [
              Tab(child: Text('Day', style: TextStyle(color: Colors.white))),
              Tab(child: Text('Week', style: TextStyle(color: Colors.white))),
              Tab(child: Text('Month', style: TextStyle(color: Colors.white))),
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
              title: 'Hourly Trend',
              trendWidget: TrendSection(
                counts: _hourlyCounts,
                isSparkline: true,
                showXAxis: true,
              ),
        );
  }

  Widget _buildWeekView() {
    return _buildCommonBody(
              title: 'Weekly Trend',
              trendWidget: TrendSection(
                counts: _weeklyCounts,
              ),
        );
  }

  Widget _buildMonthView() {
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
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                _kpiCard('Alerts', _formatDelta(_alertsDelta), _alertsDelta >= 0 ? Icons.trending_up : Icons.trending_down, _alertsDelta >= 0 ? Colors.green : Colors.redAccent),
                _kpiCard('Hours', _formatDelta(_hoursDelta), _hoursDelta >= 0 ? Icons.trending_up : Icons.trending_down, _hoursDelta >= 0 ? Colors.green : Colors.redAccent),
              ],
            ),
            const SizedBox(height: 24),

            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))],
              ),
              padding: const EdgeInsets.all(16),
              child: trendWidget,
            ),

            const SizedBox(height: 24),
            const Text('Recent Issues', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            RecentDetectionsList(detections: _recentDetections),
          ],
        ),
      ),
    );
  }

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
}