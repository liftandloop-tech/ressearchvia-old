import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YouTubeVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const YouTubeVideoPlayer({super.key, required this.videoUrl});

  @override
  State<YouTubeVideoPlayer> createState() => _YouTubeVideoPlayerState();
}

class _YouTubeVideoPlayerState extends State<YouTubeVideoPlayer> {
  late YoutubePlayerController _controller;
  bool _isValidUrl = false;
  bool _isShorts = false;

  @override
  void initState() {
    super.initState();
    debugPrint('DEBUG: YouTubeVideoPlayer initializing with URL: ${widget.videoUrl}');
    
    _isShorts = widget.videoUrl.contains('/shorts/');
    String? videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    
    // Fallback for Shorts if standard extraction fails
    if (videoId == null && _isShorts) {
      final segments = widget.videoUrl.split('/shorts/');
      if (segments.length > 1) {
        videoId = segments[1].split('?')[0].split('&')[0];
        debugPrint('DEBUG: Extracted Shorts ID: $videoId');
      }
    }

    if (videoId != null && videoId.isNotEmpty) {
      debugPrint('DEBUG: Initializing controller for ID: $videoId (isShorts: $_isShorts)');
      _isValidUrl = true;
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
        ),
      );
    } else {
      debugPrint('DEBUG: Failed to extract video ID from URL: ${widget.videoUrl}');
    }
  }

  @override
  void dispose() {
    if (_isValidUrl) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isValidUrl) {
      if (widget.videoUrl.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'DEBUG: Invalid YouTube URL or format: "${widget.videoUrl}"',
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Video Overview',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xff163174),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: Colors.black,
              child: YoutubePlayer(
                controller: _controller,
                aspectRatio: _isShorts ? 9 / 16 : 16 / 9,
                showVideoProgressIndicator: true,
                progressIndicatorColor: Colors.red,
                bottomActions: [
                  const SizedBox(width: 14.0),
                  CurrentPosition(),
                  const SizedBox(width: 8.0),
                  ProgressBar(isExpanded: true),
                  RemainingDuration(),
                  const PlaybackSpeedButton(),
                ],
                onReady: () {
                  debugPrint('DEBUG: YoutubePlayer is ready');
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
