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
  
  // Menu Radial State
  bool _isMenuOpen = false;
  bool _isShareMenuOpen = false;

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
  
  void _toggleMenu() {
    setState(() {
      if (_isMenuOpen) {
        _isMenuOpen = false;
        _isShareMenuOpen = false;
      } else {
        _isMenuOpen = true;
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
      onTap: () {
        if (_isMenuOpen) {
           _toggleMenu();
        } else {
           widget.onTap();
        }
      },
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
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _isMenuOpen ? 0.3 : 1.0,
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
                ),
                
                // Radial Menu (Right)
                SizedBox(
                  width: 64,
                  height: 200, // Area para os botões expandirem
                  child: Stack(
                     alignment: Alignment.bottomCenter,
                     clipBehavior: Clip.none, // Permitir overflow se necessário
                     children: [
                        // --- Radial Buttons ---
                        // Like (Top)
                        _buildRadialButton(
                           index: 0,
                           offset: const Offset(0, -80),
                           icon: widget.video.isLiked ? Icons.favorite : Icons.favorite_border,
                           color: widget.video.isLiked ? Colors.red : Colors.white,
                           onTap: widget.onLike,
                           delay: 0,
                        ),
                        // Share (Top-Left diagonal approx) -> Using simplified vertical stack for Flutter Layout stability for now
                        // Or implementing exact radial coordinates:
                        // Share (Left-Top) [-45px, -65px]
                        _buildRadialButton(
                           index: 1,
                           offset: const Offset(-45, -65),
                           icon: Icons.share,
                           onTap: () => setState(() => _isShareMenuOpen = true), // Should open sub-menu
                           delay: 25,
                           disabled: _isShareMenuOpen,
                        ),
                        // Follow (Left) [-70px, -35px]
                        _buildRadialButton(
                           index: 2,
                           offset: const Offset(-70, -35),
                           icon: Icons.person_add,
                           onTap: () {
                             // Toggle Follow Logic
                           }, 
                           delay: 50,
                           disabled: _isShareMenuOpen,
                        ),
                        // Save (Bottom-Left) [-80px, 0]
                        _buildRadialButton(
                           index: 3,
                           offset: const Offset(-80, 0),
                           icon: Icons.bookmark_border,
                           onTap: () {},
                           delay: 75,
                           disabled: _isShareMenuOpen,
                        ),
                        
                        // Avatar Trigger (Main)
                        Positioned(
                          bottom: 0,
                          child: GestureDetector(
                            onTap: _toggleMenu,
                            child: AnimatedScale(
                               scale: _isMenuOpen ? 0.9 : 1.0,
                               duration: const Duration(milliseconds: 300),
                               child: Container(
                                 decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                       color: _isMenuOpen ? RhemaColors.gold : Colors.white, 
                                       width: _isMenuOpen ? 3 : 2
                                    ),
                                    boxShadow: [
                                      if (_isMenuOpen) const BoxShadow(color: Colors.black26, blurRadius: 10)
                                    ]
                                 ),
                                 child: CircleAvatar(
                                    radius: 28,
                                    backgroundImage: user.avatar != null ? CachedNetworkImageProvider(user.avatar!) : null,
                                    child: user.avatar == null ? const Icon(Icons.person) : null,
                                 ),
                               ),
                            ),
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
    );
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
       return CachedNetworkImage(
          imageUrl: widget.video.thumbnailUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(color: Colors.black),
          errorWidget: (context, url, err) => Container(color: Colors.black),
       );
     }
     return Container(color: Colors.black);
  }

  Widget _buildRadialButton({
    required int index,
    required Offset offset,
    required IconData icon,
    required VoidCallback onTap,
    required int delay,
    Color color = Colors.white,
    bool disabled = false,
  }) {
      // Logic: If menu is closed, translate to 0 (hidden behind avatar)
      // If menu is open, translate to offset.
      final targetOffset = _isMenuOpen ? offset : Offset.zero;
      final opacity = _isMenuOpen ? 1.0 : 0.0;
      final scale = _isMenuOpen ? 1.0 : 0.5;
      
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        bottom: -targetOffset.dy, // Inverting Y because Stack bottom alignment
        right: -targetOffset.dx,  // Inverting X because Stack is aligned but we want left relative
        // Correction: Positioned relative to the stack center or bottom-center?
        // Stack alignment is bottomCenter.
        // Let's use left/bottom logic relative to the center of Avatar.
        // If bottom=0 is avatar bottom.
        // We want offset relative to the center.
        // Let's rely on Transform.translate
        
        child: AnimatedContainer(
           duration: Duration(milliseconds: 300 + delay),
           curve: Curves.easeOutBack,
           transform: Matrix4.translationValues(
              _isMenuOpen ? offset.dx : 0, 
              _isMenuOpen ? offset.dy : 0, 
              0
           )..scale(scale),
           child: AnimatedOpacity(
             duration: const Duration(milliseconds: 200),
             opacity: opacity,
             child: GestureDetector(
               onTap: onTap,
               child: Container(
                 width: 40,
                 height: 40,
                 decoration: BoxDecoration(
                   color: Colors.black45,
                   shape: BoxShape.circle,
                   border: Border.all(color: Colors.white24, width: 1),
                   boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                 ),
                 child: Icon(icon, color: color, size: 20),
               ),
             ),
           ),
        )
      );
  }
}
