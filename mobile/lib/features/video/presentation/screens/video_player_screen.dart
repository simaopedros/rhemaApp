import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rhema_app/core/theme/app_theme.dart';
import 'package:rhema_app/features/feed/data/models/video_model.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final String videoId;
  final VideoModel? video;

  const VideoPlayerScreen({
    super.key, 
    required this.videoId,
    this.video,
  });

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  bool _isPlaying = true;
  bool _showControls = true;
  bool _isFullscreen = false;
  double _currentPosition = 0.0;
  VideoModel? _videoData;
  bool _isLoading = true;
  VideoPlayerController? _videoController;
  bool _isPlayerReady = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    if (widget.video != null) {
      if (mounted) {
        setState(() {
          _videoData = widget.video;
          _isLoading = false;
        });
        _initializePlayer(widget.video!.videoUrl);
      }
      return;
    }
    // Mock fallback or fetching logic if needed
    setState(() => _isLoading = false);
  }

  Future<void> _initializePlayer(String url) async {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    
    try {
      await _videoController!.initialize();
      _videoController!.addListener(_videoListener);
      await _videoController!.play();
      
      if (mounted) {
        setState(() {
          _isPlayerReady = true;
          _isPlaying = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar vídeo: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _videoListener() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      final position = _videoController!.value.position.inSeconds.toDouble();
      final duration = _videoController!.value.duration.inSeconds.toDouble();
      
      // Update state only if changed significantly to avoid spam
      if (mounted && (position - _currentPosition).abs() >= 1) {
        setState(() {
          _currentPosition = position;
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // Helper getters to safer access
  String get _url => _videoData?.videoUrl ?? '';
  String get _thumb => _videoData?.thumbnailUrl ?? '';
  String get _title => _videoData?.title ?? '';
  String get _desc => _videoData?.description ?? '';
  int get _likes => _videoData?.likes ?? 0;
  int get _duration => _videoController?.value.duration.inSeconds ?? _videoData?.duration ?? 0; 
  String get _views => _videoData?.views ?? '0';
  String get _postedAt => _videoData?.postedAt ?? '';
  UserShortModel? get _user => _videoData?.user;

  void _togglePlayPause() {
    if (_videoController == null || !_isPlayerReady) return;

    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _videoController!.play();
      } else {
        _videoController!.pause();
      }
    });
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  String _formatDuration(double seconds) {
    if (seconds.isNaN || seconds.isInfinite) return '00:00';
    final mins = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: RhemaColors.primary50,
        body: Center(child: CircularProgressIndicator(color: RhemaColors.gold)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: RhemaColors.primary50,
        appBar: AppBar(
          backgroundColor: Colors.transparent, 
          leading: const BackButton(color: RhemaColors.primary900),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: RhemaColors.error, size: 48),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: RhemaColors.primary900),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                      _isLoading = true;
                    });
                    _initializePlayer(_url);
                  },
                  child: const Text('Tentar Novamente'),
                )
              ],
            ),
          ),
        ),
      );
    }
    
    if (_videoData == null) {
      return Scaffold(
        backgroundColor: RhemaColors.primary50,
        appBar: AppBar(backgroundColor: Colors.transparent, leading: const BackButton(color: RhemaColors.primary900)),
        body: const Center(child: Text('Erro ao carregar vídeo', style: TextStyle(color: RhemaColors.primary900))),
      );
    }

    return Scaffold(
      // Fullscreen keeps black for immersion, Normal mode uses light theme
      backgroundColor: _isFullscreen ? Colors.black : RhemaColors.primary50,
      body: _isFullscreen
          ? _buildFullscreenPlayer()
          : _buildNormalLayout(),
    );
  }

  Widget _buildFullscreenPlayer() {
    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: Stack(
        fit: StackFit.expand,
        children: [
                // Video Player or Placeholder
                if (_isPlayerReady && _videoController != null)
                  Center(
                    child: AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                  )
                else
                  CachedNetworkImage(
                    imageUrl: _thumb,
                    fit: BoxFit.cover,
                  ),

          // Controls overlay
          if (_showControls)
            Container(
              color: Colors.black38,
              child: Stack(
                children: [
                  // Top bar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _toggleFullscreen,
                              icon: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 28),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.more_vert, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Center play/pause
                  Center(
                    child: IconButton(
                      onPressed: _togglePlayPause,
                      icon: Icon(
                        _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: Colors.white,
                        size: 80,
                      ),
                    ),
                  ),

                  // Bottom controls
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Progress bar
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              ),
                              child: Slider(
                                value: _currentPosition,
                                min: 0,
                                max: _duration.toDouble() > 0 ? _duration.toDouble() : 1.0, 
                                activeColor: RhemaColors.gold,
                                inactiveColor: Colors.white38,
                                onChanged: (value) {
                                   setState(() => _currentPosition = value);
                                   _videoController?.seekTo(Duration(seconds: value.toInt()));
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(_currentPosition),
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                                Text(
                                  _formatDuration(_duration.toDouble()),
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNormalLayout() {
    return Column(
      children: [
        // Video Player Area - Keeps black background for the player itself
        GestureDetector(
          onTap: () => setState(() => _showControls = !_showControls),
          child: Container(
            color: Colors.black,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Video Player or Placeholder
                  if (_isPlayerReady && _videoController != null)
                    Center(
                      child: AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),
                    )
                  else
                    CachedNetworkImage(
                      imageUrl: _thumb,
                      fit: BoxFit.cover,
                    ),

                  // Controls overlay
                  if (_showControls)
                    Container(
                      color: Colors.black38,
                      child: Stack(
                        children: [
                          // Back button
                          Positioned(
                            top: 0,
                            left: 0,
                            child: SafeArea(
                              child: IconButton(
                                onPressed: () => context.pop(),
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                              ),
                            ),
                          ),

                          // Center play/pause
                          Center(
                            child: IconButton(
                              onPressed: _togglePlayPause,
                              icon: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 56,
                              ),
                            ),
                          ),

                          // Fullscreen button
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: IconButton(
                              onPressed: _toggleFullscreen,
                              icon: const Icon(Icons.fullscreen, color: Colors.white),
                            ),
                          ),

                          // Progress bar
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Column(
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 2,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                                  ),
                                  child: Slider(
                                    value: _currentPosition,
                                    min: 0,
                                    max: _duration.toDouble() > 0 ? _duration.toDouble() : 1.0,
                                    activeColor: RhemaColors.gold,
                                    inactiveColor: Colors.white38,
                                    onChanged: (value) {
                                      setState(() => _currentPosition = value);
                                      _videoController?.seekTo(Duration(seconds: value.toInt()));
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Video details - Light Theme!
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        _title,
                        style: const TextStyle(
                          color: RhemaColors.primary900, // Light theme color
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Stats
                      Text(
                        '$_views visualizações · $_postedAt',
                        style: const TextStyle(
                          color: RhemaColors.primary500, // Light theme muted
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildActionButton(Icons.thumb_up_outlined, _formatNumber(_likes)),
                          _buildActionButton(Icons.thumb_down_outlined, 'Dislike'),
                          _buildActionButton(Icons.share, 'Compartilhar'),
                          _buildActionButton(Icons.download, 'Salvar'),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(color: RhemaColors.primary200), // Light theme divider

                // Channel info
                if (_user != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: _user!.avatar != null ? CachedNetworkImageProvider(_user!.avatar!) : null,
                        child: _user!.avatar == null ? Text(_user!.name[0]) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _user!.name,
                                  style: const TextStyle(
                                    color: RhemaColors.primary900, // Light theme
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                if (_user!.isVerified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified, color: RhemaColors.gold, size: 16),
                                ],
                              ],
                            ),
                            // Follower count mock or if avail in model
                           const Text(
                              'Seguidores',
                              style: TextStyle(color: RhemaColors.primary500, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RhemaColors.gold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        child: const Text('Seguir'),
                      ),
                    ],
                  ),
                ),

                const Divider(color: RhemaColors.primary200),

                // Description
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _desc,
                    style: const TextStyle(
                      color: RhemaColors.primary800, // Light theme text
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper for light theme action buttons in normal layout
  Widget _buildActionButton(IconData icon, String label) {
    // Note: Video details uses dark icons now
    return Column(
      children: [
        Icon(icon, color: RhemaColors.primary700, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: RhemaColors.primary500, fontSize: 12),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}
