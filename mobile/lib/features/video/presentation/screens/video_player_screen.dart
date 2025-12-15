import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rhema_app/core/theme/app_theme.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final String videoId;

  const VideoPlayerScreen({super.key, required this.videoId});

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  bool _isPlaying = true;
  bool _showControls = true;
  bool _isFullscreen = false;
  double _currentPosition = 0.0;
  final double _duration = 180.0; // 3 minutos mock

  // Mock video data
  final Map<String, dynamic> _videoData = {
    'id': 'mock',
    'title': 'Estudo Profundo: Romanos 8 - Nada Pode Nos Separar do Amor de Deus',
    'description': '''Neste estudo, vamos explorar um dos capítulos mais poderosos da Bíblia. 
Romanos 8 nos fala sobre a certeza da salvação, a vida no Espírito, e a promessa de que absolutamente nada pode nos separar do amor de Deus em Cristo Jesus.

📖 Tópicos abordados:
• A condenação removida (v. 1-4)
• Vida segundo o Espírito (v. 5-17)
• A glória futura (v. 18-30)
• Mais que vencedores (v. 31-39)

#estudo #biblia #romanos8 #devocional #fe''',
    'thumbnail': 'https://images.unsplash.com/photo-1507692049790-de58293a469d?w=1080',
    'views': '89.1k',
    'likes': 22100,
    'postedAt': '3 dias atrás',
    'user': {
      'id': 'u3',
      'name': 'Pastora Helena',
      'handle': '@helena.pastora',
      'avatar': 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=100',
      'followers': '98k',
      'isVerified': true,
    },
  };

  @override
  void initState() {
    super.initState();
    // Simular progresso do vídeo
    _startProgressSimulation();
  }

  void _startProgressSimulation() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isPlaying && _currentPosition < _duration) {
        setState(() => _currentPosition += 1);
        _startProgressSimulation();
      }
    });
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _startProgressSimulation();
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
    final mins = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _videoData['user'] as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _isFullscreen
          ? _buildFullscreenPlayer()
          : _buildNormalLayout(user),
    );
  }

  Widget _buildFullscreenPlayer() {
    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video placeholder
          CachedNetworkImage(
            imageUrl: _videoData['thumbnail'],
            fit: BoxFit.contain,
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
                                max: _duration,
                                activeColor: RhemaColors.gold,
                                inactiveColor: Colors.white38,
                                onChanged: (value) => setState(() => _currentPosition = value),
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
                                  _formatDuration(_duration),
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

  Widget _buildNormalLayout(Map<String, dynamic> user) {
    return Column(
      children: [
        // Video Player Area
        GestureDetector(
          onTap: () => setState(() => _showControls = !_showControls),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Video placeholder
                CachedNetworkImage(
                  imageUrl: _videoData['thumbnail'],
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
                                  max: _duration,
                                  activeColor: RhemaColors.gold,
                                  inactiveColor: Colors.white38,
                                  onChanged: (value) => setState(() => _currentPosition = value),
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

        // Video details
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
                        _videoData['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Stats
                      Text(
                        '${_videoData['views']} visualizações · ${_videoData['postedAt']}',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildActionButton(Icons.thumb_up_outlined, _formatNumber(_videoData['likes'])),
                          _buildActionButton(Icons.thumb_down_outlined, 'Dislike'),
                          _buildActionButton(Icons.share, 'Compartilhar'),
                          _buildActionButton(Icons.download, 'Salvar'),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(color: Colors.white12),

                // Channel info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: CachedNetworkImageProvider(user['avatar']),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  user['name'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                if (user['isVerified'] == true) ...[
                                  const SizedBox(width: 4),
                                  Icon(Icons.verified, color: RhemaColors.gold, size: 16),
                                ],
                              ],
                            ),
                            Text(
                              '${user['followers']} seguidores',
                              style: TextStyle(color: Colors.white54, fontSize: 13),
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

                const Divider(color: Colors.white12),

                // Description
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _videoData['description'],
                    style: TextStyle(
                      color: Colors.white70,
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

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
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
