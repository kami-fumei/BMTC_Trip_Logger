// lib/widgets/full_video_player.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:open_filex/open_filex.dart';

/// Full-screen video player widget
class FullVideoPlayer extends StatefulWidget {
  final String videoPath;

  const FullVideoPlayer({Key? key, required this.videoPath}) : super(key: key);

  @override
  _FullVideoPlayerState createState() => _FullVideoPlayerState();
}

class _FullVideoPlayerState extends State<FullVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _isPlaying = true;
      });
    _controller.addListener(_updateState);
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_updateState);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                : const CircularProgressIndicator(),
          ),
          // Close button
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          // 3-dots menu
          Positioned(
            top: 40,
            right: 16,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              color: Colors.white,
              onSelected: (value) async {
                if (value == 'open_with') {
                  await OpenFilex.open(widget.videoPath);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'open_with',
                  child: Text('Open with Photos app'),
                ),
              ],
            ),
          ),
          // Play/Pause button and Seek bar
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_controller.value.isInitialized)
                  Slider(
                    value: _controller.value.position.inMilliseconds.toDouble(),
                    min: 0,
                    max: _controller.value.duration.inMilliseconds.toDouble(),
                    onChanged: (value) {
                      _controller.seekTo(Duration(milliseconds: value.toInt()));
                    },
                    activeColor: Colors.white,
                    inactiveColor: Colors.white38,
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          if (_controller.value.isPlaying) {
                            _controller.pause();
                            _isPlaying = false;
                          } else {
                            _controller.play();
                            _isPlaying = true;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FullImageViewer extends StatefulWidget {
  final List<String> imagePaths; // local file paths
  final int initialIndex;

  const FullImageViewer({
    Key? key,
    required this.imagePaths,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  _FullImageViewerState createState() => _FullImageViewerState();
}

class _FullImageViewerState extends State<FullImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imagePaths.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.file(
                    File(widget.imagePaths[index]),
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
          // Close button
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          // Indicator
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '${_currentIndex + 1} / ${widget.imagePaths.length}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

