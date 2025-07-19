// lib/pages/image_alerts_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../models/alert.dart';
import '../services/image_alerts_service.dart';
import 'full_screen_image_view.dart';

class ImageAlertsPage extends StatefulWidget {
  final String driverId;
  const ImageAlertsPage({Key? key, required this.driverId}) : super(key: key);

  @override
  State<ImageAlertsPage> createState() => _ImageAlertsPageState();
}

class _ImageAlertsPageState extends State<ImageAlertsPage> {
  static const _pageSize = 10;
  final _service = ImageAlertsService();
  final _scrollController = ScrollController();

  List<Alert> _alerts = [];
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  bool _loadingPage = false;
  bool _hasMore = true;

  // filter state
  String _filterType = 'All';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _fetchNextPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_loadingPage &&
        _hasMore &&
        _scrollController.position.pixels >
            _scrollController.position.maxScrollExtent - 200) {
      _fetchNextPage();
    }
  }

  Future<void> _fetchNextPage() async {
    if (_loadingPage || !_hasMore) return;
    setState(() => _loadingPage = true);

    final snap = await _service.fetchAlertsPage(
      driverId: widget.driverId,
      filterType: _filterType,
      startDate: _startDate,
      endDate: _endDate,
      pageSize: _pageSize,
      startAfterDoc: _lastDoc,
    );

    if (snap.docs.isNotEmpty) {
      _lastDoc = snap.docs.last;
      setState(() {
        _alerts.addAll(
          snap.docs.map((d) => Alert.fromMap(d.id, d.data())).toList(),
        );
      });
    } else {
      _hasMore = false;
    }

    setState(() => _loadingPage = false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _filterType = 'All';         // reset type filter
        _startDate  = picked;
        _endDate    = picked;       // same-day filter
        _alerts.clear();
        _lastDoc    = null;
        _hasMore    = true;
      });
      _fetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Image Alerts', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Date picker button:
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.blueAccent),
            onPressed: _pickDate,
            tooltip: _startDate == null
                ? 'Filter by date'
                : 'Filtered: ${DateFormat.yMMMd().format(_startDate!)}',
          ),
          // Existing type‐filter menu button:
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.blueAccent),
            onPressed: _openFilterMenu,
          ),
        ],
      ),

      body: _alerts.isEmpty && _loadingPage
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: GridView.builder(
          controller: _scrollController,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 3 / 4,
          ),
          itemCount: _alerts.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _alerts.length) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _loadingPage
                    ? Center(
                  key: const ValueKey('loading'),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: Lottie.asset(
                      'assets/animations/loading_animation.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                )
                    : const SizedBox.shrink(),
              );
            }
            return _buildAnimatedCard(_alerts[index]);
          },
        ),
      ),
    );
  }

  Future<void> _openFilterMenu() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Filter Alerts'),
        children: [
          ...['All', 'Drowsy', 'Distracted', 'No Seatbelt', 'Yawning']
              .map((t) => SimpleDialogOption(
            child: Text(t),
            onPressed: () => Navigator.pop(context, t),
          )),
        ],
      ),
    );
    if (choice == null || choice == _filterType) return;

    setState(() {
      _filterType = choice;
      _startDate = null;
      _endDate = null;
      _alerts.clear();
      _lastDoc = null;
      _hasMore = true;
    });
    _fetchNextPage();
  }

  Widget _buildAnimatedCard(Alert a) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullScreenImageView(imageUrl: a.imageUrl),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Hero(
                tag: a.imageUrl,
                child: ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    a.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (ctx, child, prog) {
                      if (prog == null) return child;
                      return Container(
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                      );
                    },
                    errorBuilder: (ctx, err, st) => Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.broken_image,
                          size: 48, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(a.type,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                DateFormat.yMMMd().add_jm().format(a.timestamp.toLocal()),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
