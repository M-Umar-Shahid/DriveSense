import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import '../../models/alert.dart';
import '../../services/image_alerts_service.dart';
import '../components/image_alerts_screen_component/alert_card.dart';
import 'full_screen_image_view.dart';
import 'main_app_screen.dart';

class ImageAlertsPage extends StatefulWidget {
  const ImageAlertsPage({Key? key}) : super(key: key);

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
  String _filter = 'All';

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
      filter: _filter,
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

  Future<void> _openFilterMenu() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Filter by type'),
        children: ['All', 'Drowsy', 'Distracted', 'No Seatbelt', 'Yawning']
            .map((t) => SimpleDialogOption(
          child: Text(t),
          onPressed: () => Navigator.pop(context, t),
        ))
            .toList(),
      ),
    );
    if (choice != null && choice != _filter) {
      setState(() {
        _filter = choice;
        _alerts.clear();
        _lastDoc = null;
        _hasMore = true;
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
        title: const Text('Image Alerts',
            style: TextStyle(color: Colors.black)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainAppScreen()),
                (r) => false,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.blueAccent),
            onPressed: _openFilterMenu,
          )
        ],
      ),
      body: _alerts.isEmpty && _loadingPage
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: GridView.builder(
          controller: _scrollController,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 3 / 4,
          ),
          itemCount: _alerts.length + (_hasMore ? 1 : 0),
          // <-- note two parameters here: context and index
          itemBuilder: (BuildContext context, int index) {
            // if we've scrolled to the “loading” slot
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

            // now it's safe to grab the alert at `index`
            final a = _alerts[index];
            return _buildAnimatedCard(a, index);
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(Alert a, int index) {
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
                child: FadeInImage.assetNetwork(
                  placeholder: 'assets/placeholder.jpg',
                  image: a.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                a.type,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                a.timestamp.toLocal().toString().split('.')[0],
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
