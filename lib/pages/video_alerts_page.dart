import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoAlertsPage extends StatelessWidget {
  final List<VideoClip> videoClips = [
    VideoClip(
      title: "Drowsiness Alert",
      timestamp: "2024-12-12 08:30 AM",
      videoPath: "assets/videos/clip1.mp4",
    ),
    VideoClip(
      title: "Seatbelt Not Fastened",
      timestamp: "2024-12-12 09:00 AM",
      videoPath: "assets/videos/clip2.mp4",
    ),
    VideoClip(
      title: "Distraction Detected",
      timestamp: "2024-12-12 09:45 AM",
      videoPath: "assets/videos/clip3.mp4",
    ),
  ];

  VideoAlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("Alert Video Clips"),
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: videoClips.length,
        itemBuilder: (context, index) {
          final clip = videoClips[index];
          return _videoCard(context, clip);
        },
      ),
    );
  }

  Widget _videoCard(BuildContext context, VideoClip clip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20.0),
      elevation: 5.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: const Icon(Icons.videocam, size: 40.0, color: Colors.blueAccent),
        title: Text(
          clip.title,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        subtitle: Text(
          clip.timestamp,
          style: const TextStyle(fontSize: 14.0, color: Colors.grey),
        ),
        trailing: const Icon(Icons.play_arrow, color: Colors.blueAccent, size: 30.0),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(videoPath: clip.videoPath),
            ),
          );
        },
      ),
    );
  }
}

class VideoClip {
  final String title;
  final String timestamp;
  final String videoPath;

  VideoClip({
    required this.title,
    required this.timestamp,
    required this.videoPath,
  });
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;

  const VideoPlayerScreen({super.key, required this.videoPath});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoPath)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Playing Video"),
      ),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () {
          setState(() {
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              _controller.play();
            }
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
        ),
      ),
    );
  }
}
