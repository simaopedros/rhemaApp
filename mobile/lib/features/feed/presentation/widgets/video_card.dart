import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rhema_app/features/feed/data/models/video_model.dart';
import 'package:rhema_app/core/theme/app_theme.dart';
import 'package:rhema_app/features/feed/data/services/video_preload_service.dart';
import 'package:video_player/video_player.dart';
import 'dart:math' as math;

class VideoCard extends StatefulWidget {
  final VideoModel video;
  final bool isActive;
  final VoidCallback onLike;
  final VoidCallback onComment; // Swipe Up
  final VoidCallback onShare;
  final VoidCallback onUserTap;
  final VoidCallback onTap; // Open Detail
  final VoidCallback onSwipeUp;
  final VoidCallback onSwipeDown;

  const VideoCard({
    super.key,
    required this.video,
    required this.isActive,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onUserTap,
    required this.onTap,
    required this.onSwipeUp,
    required this.onSwipeDown,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> with TickerProviderStateMixin {
  late AnimationController _heartController;
  final VideoPreloadService _preloadService = VideoPreloadService();
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _showDoubleTapHeart = false;
  bool _isMenuOpen = false;
  


  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    if (widget.isActive) {
      _initializeVideo();
    }
  }

  @override
  void didUpdateWidget(VideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _initializeVideo();
      } else {
        _videoController?.pause();
        // Fechar menus se sair do vídeo
        if (_isMenuOpen) setState(() => _isMenuOpen = false);
      }
    }
  }

  Future<void> _initializeVideo() async {
    // Lógica original de inicialização
    final url = widget.video.videoUrl;
    final cachedController = _preloadService.getCachedController(url);
    
    if (cachedController != null && cachedController.value.isInitialized) {
      if (mounted) {
        setState(() {
          _videoController = cachedController;
          _isInitialized = true;
        });
        await cachedController.seekTo(Duration.zero);
        cachedController.play();
      }
      return;
    }
    
    try {
      final controller = await _preloadService.getController(url);
      if (controller != null && mounted) {
        setState(() {
          _videoController = controller;
          _isInitialized = true;
        });
        if (widget.isActive) {
          controller.play();
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar vídeo: $e');
    }
  }

  @override
  void dispose() {
    _heartController.dispose();
    // NÃO dispose do controller aqui - ele é gerenciado pelo PreloadService
    super.dispose();
  }

  Widget _buildVideoPlayer() {
    if (_isInitialized && _videoController != null) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _videoController!.value.size.width,
            height: _videoController!.value.size.height,
            child: VideoPlayer(_videoController!),
          ),
        ),
      );
    }

    if (widget.video.thumbnailUrl != null) {
      return SizedBox.expand(
        child: CachedNetworkImage(
          imageUrl: widget.video.thumbnailUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(color: Colors.white24),
          ),
          errorWidget: (context, url, error) => Container(color: Colors.black),
        ),
      );
    }

    return Container(color: Colors.black);
  }

  void _handleDoubleTap() {
    if (!widget.video.isLiked) {
      widget.onLike();
    }
    setState(() => _showDoubleTapHeart = true);
    _heartController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() => _showDoubleTapHeart = false);
      }
    });
  }
  


  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    // Implementar lógica de threshold se necessário
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -500) {
      // Swipe Up -> Comentários
      widget.onSwipeUp();
    } else if (velocity > 500) {
      // Swipe Down -> Stats
      widget.onSwipeDown();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.video.user;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return GestureDetector(
      behavior: HitTestBehavior.translucent, // Permite que PageView receba gestos
      onVerticalDragEnd: _handleVerticalDragEnd,
      onDoubleTap: _handleDoubleTap,
      onTap: widget.onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Video Layer
          _buildVideoPlayer(),

          // 2. Gradient Layer
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.transparent,
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),
          
          // 3. Double Tap Heart
          if (_showDoubleTapHeart)
            Center(
              child: AnimatedBuilder(
                animation: _heartController,
                builder: (context, child) {
                  return Opacity(
                    opacity: 1 - _heartController.value,
                    child: Transform.scale(
                      scale: 1 + (_heartController.value * 0.5),
                      child: const Icon(Icons.favorite, color: Colors.white, size: 120),
                    ),
                  );
                },
              ),
            ),

          // Progress Indicator
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _isInitialized && _videoController != null
                ? VideoProgressIndicator(
                    _videoController!,
                    allowScrubbing: false,
                    padding: EdgeInsets.zero,
                    colors: const VideoProgressColors(
                      playedColor: RhemaColors.gold, // Usando a cor dourada do tema
                      backgroundColor: Colors.grey,
                      bufferedColor: Colors.white24,
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // 4. Content Content (Bottom)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24 + bottomPadding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Text Info (Left)
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         Row(
                          children: [
                            Text(
                              user.handle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                              ),
                            ),
                            if (user.isVerified) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.verified, color: RhemaColors.gold, size: 18),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (widget.video.description != null)
                          Text(
                            widget.video.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.3,
                              shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                            ),
                          ),
                         const SizedBox(height: 8),
                         // Music Note placeholder
                         Row(
                           children: [
                             const Icon(Icons.music_note, size: 14, color: Colors.white70),
                             const SizedBox(width: 4),
                             Text('Som original - ${user.name}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                           ],
                         )
                      ],
                    ),
                  ),
                
                // Lateral Action Menu (Right)
                Container(
                  width: 60,
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       _buildAvatarButton(user),
                       const SizedBox(height: 20),
                       _buildSideActionButton(
                         icon: widget.video.isLiked ? Icons.favorite : Icons.favorite_border,
                         color: widget.video.isLiked ? Colors.red : Colors.white,
                         label: _compactFormat(widget.video.likes),
                         onTap: widget.onLike,
                       ),
                       const SizedBox(height: 16),
                       _buildSideActionButton(
                         icon: Icons.comment_rounded,
                         label: _compactFormat(widget.video.comments),
                         onTap: widget.onComment,
                       ),
                       const SizedBox(height: 16),
                       _buildSideActionButton(
                         icon: Icons.share_rounded,
                         label: 'Comp.',
                         onTap: widget.onShare,
                         iconSize: 30, // Share icon slightly smaller visually depending on font
                       ),
                       const SizedBox(height: 16),
                       _buildSideActionButton(
                         icon: Icons.bookmark_border_rounded,
                         label: 'Salvar',
                         onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salvo para ver depois!')));
                         },
                       ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper para formatar números (1.2k, 1M, etc)
  String _compactFormat(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toString();
  }

  Widget _buildAvatarButton(dynamic user) {
     return Stack(
       clipBehavior: Clip.none,
       alignment: Alignment.bottomCenter,
       children: [
         Container(
           padding: const EdgeInsets.all(1),
           decoration: BoxDecoration(
             color: Colors.white,
             shape: BoxShape.circle,
           ),
           child: CircleAvatar(
             radius: 24,
             backgroundImage: user.avatar != null ? CachedNetworkImageProvider(user.avatar!) : null,
             backgroundColor: Colors.grey[800],
             child: user.avatar == null ? const Icon(Icons.person, color: Colors.white) : null,
           ),
         ),
         Positioned(
           bottom: -10,
           child: Container(
             padding: const EdgeInsets.all(2),
             decoration: const BoxDecoration(
               color: RhemaColors.gold,
               shape: BoxShape.circle,
             ),
             child: const Icon(Icons.add, color: Colors.white, size: 14),
           ),
         )
       ],
     );
  }

  Widget _buildSideActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
    double iconSize = 34,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: const [
                 BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
              ]
            ), 
            child: Icon(icon, color: color, size: iconSize, shadows: const [Shadow(color: Colors.black45, blurRadius: 10)]) 
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}
