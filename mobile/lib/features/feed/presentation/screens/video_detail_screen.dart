import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rhema_app/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:rhema_app/features/feed/data/models/video_model.dart';

class VideoDetailScreen extends StatelessWidget {
  final VideoModel video;

  const VideoDetailScreen({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    final user = video.user;
    
    // Logic to use Parent Video (Original) if available
    final isParent = video.parentVideo != null;
    final displayVideoUrl = isParent ? video.parentVideo!.videoUrl : video.videoUrl;
    final displayThumbnailUrl = isParent 
        ? (video.parentVideo?.thumbnailUrl ?? video.thumbnailUrl ?? video.videoUrl)
        : (video.thumbnailUrl ?? video.videoUrl);
    final displayDescription = isParent ? (video.parentVideo?.description ?? video.description) : video.description;
    
    return Scaffold(
      backgroundColor: Colors.grey[50], // rhema-50
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
                    fontFamily: 'Serif', // Fallback if 'Sentient' not avail
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
                    aspectRatio: 16 / 9,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          color: Colors.black,
                          child: Opacity(
                            opacity: 0.9,
                            child: CachedNetworkImage(
                              imageUrl: displayThumbnailUrl, // Shows parent thumbnail if available
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Center(
                          child: Container(
                             width: 64,
                             height: 64,
                             decoration: BoxDecoration(
                               color: Colors.white.withOpacity(0.2),
                               shape: BoxShape.circle,
                               border: Border.all(color: Colors.white.withOpacity(0.4)),
                             ),
                             child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                           ),
                        ),
                        // Progress Bar
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 4,
                            color: Colors.grey[700],
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: 0.33,
                              child: Container(color: RhemaColors.gold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Info Section
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
                                      '12.4k seguidores', // Mock
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

                  // Suggestions
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
