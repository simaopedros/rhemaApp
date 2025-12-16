import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:rhema_app/core/theme/app_theme.dart';
import 'package:rhema_app/features/feed/data/models/video_model.dart';
import 'package:rhema_app/features/feed/presentation/widgets/video_card.dart';
import 'package:rhema_app/features/feed/presentation/widgets/comments_drawer.dart';
import 'package:rhema_app/features/feed/presentation/widgets/video_stats_drawer.dart';
// Importando VideoCard existente, mas vamos usá-lo com dados mockados.

class FeedScreenV2 extends StatefulWidget {
  const FeedScreenV2({super.key});

  @override
  State<FeedScreenV2> createState() => _FeedScreenV2State();
}

class _FeedScreenV2State extends State<FeedScreenV2> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  
  // MOCK DATA HARDCODED - Garantia de funcionamento
  final List<VideoModel> _mockVideos = [
    VideoModel(
      id: 'mock1',
      title: 'Ressuscita-me',
      description: 'Um momento de adoração profunda. ✨🙌 #louvor',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
      user: UserShortModel(id: 'u2', name: 'Aline Barros', handle: '@alinebarros', isVerified: true, avatar: 'https://i.pravatar.cc/150?u=a'),
      likes: 3200, comments: 450, shares: 1200, views: '45k', isLiked: true, tags: [],
    ),
    VideoModel(
      id: 'mock2',
      title: 'Benção do Dia',
      description: 'Que a paz de Cristo esteja em seus corações. 🙏🕊️',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      user: UserShortModel(id: 'u1', name: 'Padre Marcelo', handle: '@padremarcelo', isVerified: true, avatar: 'https://i.pravatar.cc/150?u=b'),
      likes: 1500, comments: 100, shares: 50, views: '12k', isLiked: false, tags: [],
    ),
    VideoModel(
      id: 'mock3',
      title: 'Mensagem do Papa',
      description: 'O amor vence o ódio. 🇻🇦❤️ #vaticano',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
      user: UserShortModel(id: 'u3', name: 'Papa Francisco', handle: '@pontifex', isVerified: true, avatar: 'https://i.pravatar.cc/150?u=c'),
      likes: 50000, comments: 2000, shares: 15000, views: '200k', isLiked: false, tags: [],
    ),
    VideoModel(
       id: 'mock4',
       title: 'Pregação Jovem',
       description: 'Não desista dos seus sonhos! 🔥📖',
       videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
       user: UserShortModel(id: 'u4', name: 'Deive Leonardo', handle: '@deive', isVerified: true, avatar: 'https://i.pravatar.cc/150?u=d'),
       likes: 8900, comments: 340, shares: 2100, views: '78k', isLiked: false, tags: [],
     ),
     VideoModel(
       id: 'mock5',
       title: 'Acampamento',
       description: 'Juventude santa! ⛺🔥',
       videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
       user: UserShortModel(id: 'u5', name: 'Shalom', handle: '@comshalom', isVerified: true, avatar: 'https://i.pravatar.cc/150?u=e'),
       likes: 4100, comments: 230, shares: 400, views: '22k', isLiked: true, tags: [],
     ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
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
            scrollDirection: Axis.horizontal,
            itemCount: _mockVideos.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              final video = _mockVideos[index];
              return VideoCard(
                video: video,
                isActive: index == _currentIndex,
                onLike: () {
                  setState(() {
                    // Toggle Mock Local
                    video.isLiked = !video.isLiked;
                  });
                },
                onComment: () {
                   _showCommentsDrawer(context, video.id);
                },
                onShare: () {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compartilhar (Mock)')));
                },
                onUserTap: () {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ir para Perfil (Mock)')));
                },
                onTap: () {
                  // Navegação Detalhada (se necessário)
                },
                onSwipeUp: () {
                   _showCommentsDrawer(context, video.id);
                },
                onSwipeDown: () {
                   VideoStatsDrawer.show(context, video: video);
                },
              );
            },
          ),
          
          // Debug Indicator
          Positioned(
             bottom: 100,
             left: 0, 
             right: 0,
             child: Center(
               child: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                 decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                 child: Text('${_currentIndex + 1} / ${_mockVideos.length}', style: const TextStyle(color: Colors.white)),
               ),
             ),
          ),

          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                bottom: 10,
              ),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black54, Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              ),
              child: const Text('RHEMA (V2)', style: TextStyle(color: RhemaColors.gold, fontWeight: FontWeight.bold, fontSize: 22)),
            ),
          )
        ],
      ),
    );
  }
  void _showCommentsDrawer(BuildContext context, String videoId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsDrawer(
        videoId: videoId,
        onClose: () => Navigator.pop(context),
      ),
    );
  }
}
