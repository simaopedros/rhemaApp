import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rhema_app/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:rhema_app/features/feed/data/models/video_model.dart';

import 'package:video_player/video_player.dart';

class VideoDetailScreen extends StatefulWidget {
  final VideoModel video;

  const VideoDetailScreen({super.key, required this.video});

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final isParent = widget.video.parentVideo != null;
    final url = isParent ? widget.video.parentVideo!.videoUrl : widget.video.videoUrl;
    
    _controller = VideoPlayerController.networkUrl(Uri.parse(url));

    try {
      await _controller.initialize();
      await _controller.play();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error initializing detail player: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    final user = video.user;
    
    final isParent = video.parentVideo != null;
    final displayDescription = isParent ? (video.parentVideo?.description ?? video.description) : video.description;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 8,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Row(
                    children: [
                      Icon(Icons.chevron_left, size: 28, color: RhemaColors.primary900),
                      const SizedBox(width: 4),
                      Text(
                        'Voltar',
                        style: TextStyle(
                          color: RhemaColors.primary900,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Rhēma Player',
                  style: TextStyle(
                    fontFamily: 'Serif',
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: RhemaColors.primary900,
                    fontSize: 18,
                  ),
                ),
                Icon(Icons.more_horiz, size: 28, color: RhemaColors.primary900),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Video Area
                  AspectRatio(
                    aspectRatio: _isInitialized ? _controller.value.aspectRatio : 16 / 9,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isInitialized)
                          VideoPlayer(_controller)
                        else
                          Container(color: Colors.black, child: const Center(child: CircularProgressIndicator())),
                        
                        // Play/Pause Overlay
                        if (_isInitialized)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _controller.value.isPlaying ? _controller.pause() : _controller.play();
                              });
                            },
                            child: Container(
                              color: Colors.transparent,
                              child: Center(
                                child: !_controller.value.isPlaying
                                    ? Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                                      )
                                    : const SizedBox(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Info Section (Rest of the code remains similar but adapted to widget.video)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (displayDescription != null)
                          Text(
                            displayDescription,
                            style: const TextStyle(
                              fontFamily: 'Serif',
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              height: 1.2,
                              color: Colors.black87,
                            ),
                          ),
                        const SizedBox(height: 16),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: user.avatar != null ? CachedNetworkImageProvider(user.avatar!) : null,
                                  child: user.avatar == null ? const Icon(Icons.person) : null,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          user.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        if (user.isVerified) ...[
                                          const SizedBox(width: 4),
                                          Icon(Icons.verified, size: 14, color: RhemaColors.gold),
                                        ],
                                      ],
                                    ),
                                    const Text(
                                      '12.4k seguidores',
                                      style: TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: RhemaColors.primary800, 
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Text(
                                    'Seguindo',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            
                            Column(
                              children: [
                                const Icon(Icons.favorite, color: Colors.grey, size: 24),
                                const SizedBox(height: 2),
                                Text(
                                  '${video.likes}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          children: video.tags.map((tag) {
                            return Chip(
                               label: Text(tag, style: TextStyle(color: RhemaColors.primary600, fontSize: 12)),
                               backgroundColor: Colors.grey[50], // rhema-50
                               side: BorderSide.none,
                               padding: EdgeInsets.zero,
                               visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  // Suggestions (Placeholder)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RELACIONADOS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Grid Placeholder
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                             crossAxisCount: 2,
                             childAspectRatio: 16/9, 
                             crossAxisSpacing: 16,
                             mainAxisSpacing: 16,
                             mainAxisExtent: 180, 
                          ),
                          itemCount: 4, // Mock
                          itemBuilder: (ctx, idx) {
                             return Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                  AspectRatio(
                                    aspectRatio: 16/9,
                                    child: Container(
                                       decoration: BoxDecoration(
                                         color: Colors.grey[300],
                                         borderRadius: BorderRadius.circular(8),
                                         image: DecorationImage(
                                            image: CachedNetworkImageProvider(video.videoUrl), // Reuse for mock
                                            fit: BoxFit.cover,
                                         ),
                                       ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    video.description ?? 'Sem descrição',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                               ],
                             );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
