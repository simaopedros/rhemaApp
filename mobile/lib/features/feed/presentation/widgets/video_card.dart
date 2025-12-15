import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rhema_app/features/feed/data/models/video_model.dart';
import 'package:rhema_app/core/theme/app_theme.dart';
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

  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> with TickerProviderStateMixin {
  late AnimationController _heartController;
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _showDoubleTapHeart = false;
  
  // Radial Menu State


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
      }
    }
  }

  Future<void> _initializeVideo() async {
    if (_videoController != null && _videoController!.dataSource == widget.video.videoUrl) {
      // Já inicializado com o mesmo vídeo, apenas play
      if (!_videoController!.value.isPlaying) {
        _videoController?.play();
      }
      return;
    }

    _disposeVideo(); // Limpar anterior

    // Criar novo controller
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.video.videoUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    try {
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        if (widget.isActive) {
          _videoController!.play();
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar vídeo: $e');
    }
  }

  void _disposeVideo() {
    _videoController?.dispose();
    _videoController = null;
    _isInitialized = false;
  }

  @override
  void dispose() {
    _heartController.dispose();
    _disposeVideo();
    super.dispose();
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

  void _handleVerticalDragEnd(DragEndDetails details) {
    // Detect Swipe Up/Down
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -500) {
      // Swipe Up (Negative velocity)
      widget.onSwipeUp();
    }
  }



  @override
  Widget build(BuildContext context) {
    final user = widget.video.user;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTap: _handleDoubleTap,
      onVerticalDragEnd: _handleVerticalDragEnd,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Video Player or Thumbnail
          if (_isInitialized && _videoController != null)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            )
          else
            CachedNetworkImage(
              imageUrl: widget.video.thumbnailUrl ?? widget.video.videoUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.black),
              errorWidget: (context, url, err) => Container(color: Colors.black),
            ),

          // 2. Double Tap Heart Animation
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

          // 3. Gradient Overlay
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

          // 4. Content Area
          Positioned(
            left: 16,
            right: 8, // Reduced spacing for sidebar
            bottom: 24 + bottomPadding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // LEFT: Text Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // User Handle & Badge
                      GestureDetector(
                        onTap: widget.onUserTap, // Also open profile on name tap
                        child: Row(
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
                      ),
                      const SizedBox(height: 8),
                      // Description
                      if (widget.video.description != null)
                        Text(
                          widget.video.description!,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.3,
                            shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                          ),
                        ),
                      const SizedBox(height: 12),

                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // RIGHT: Standard Vertical Sidebar
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar Profile Link
                    Stack(
                      alignment: Alignment.bottomCenter,
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          onTap: widget.onUserTap,
                          child: Container(
                            decoration: BoxDecoration(
                               border: Border.all(color: Colors.white, width: 1),
                               shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundImage: user.avatar != null 
                                 ? CachedNetworkImageProvider(user.avatar!)
                                 : null,
                              child: user.avatar == null ? const Icon(Icons.person) : null,
                            ),
                          ),
                        ),
                        // Follow Button Badge
                        Positioned(
                          bottom: -10,
                          child: GestureDetector(
                            onTap: widget.onUserTap, // Or follow logic
                            child: Container(
                              decoration: const BoxDecoration(
                                color: RhemaColors.gold,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(2),
                              child: const Icon(Icons.add, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Like Button
                    _SidebarButton(
                      icon: widget.video.isLiked ? Icons.favorite : Icons.favorite_rounded,
                      label: widget.video.likes.toString(),
                      color: widget.video.isLiked ? Colors.red : Colors.white,
                      onTap: widget.onLike,
                    ),

                    // Comment Button
                    _SidebarButton(
                      icon: Icons.comment_rounded,
                      label: widget.video.comments.toString(),
                      onTap: widget.onComment,
                    ),

                    // Bookmark Button
                    _SidebarButton(
                      icon: Icons.bookmark_rounded,
                      label: 'Salvar',
                      iconSize: 30, // Slightly larger visual
                      onTap: () {},
                    ),

                    // Share Button
                    _SidebarButton(
                      icon: Icons.share,
                      label: 'Partilhar', // More generic
                      onTap: widget.onShare,
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

class _SidebarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final double iconSize;

  const _SidebarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
    this.iconSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, size: iconSize, color: color,
              shadows: const [Shadow(color: Colors.black26, blurRadius: 4)],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

