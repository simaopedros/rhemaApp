import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rhema_app/core/theme/app_theme.dart';
import 'package:rhema_app/features/feed/data/models/video_model.dart';
import 'package:rhema_app/features/feed/presentation/providers/feed_provider.dart';
import 'package:rhema_app/features/feed/presentation/widgets/video_card.dart';
import 'package:rhema_app/features/feed/presentation/screens/video_detail_screen.dart';
import 'package:rhema_app/features/feed/presentation/providers/comments_controller.dart';
import 'package:intl/intl.dart';
import 'package:rhema_app/features/feed/presentation/widgets/video_stats_drawer.dart';
import 'package:rhema_app/features/feed/data/repositories/interaction_repository.dart';

/// Tipo de feed atual
enum FeedType { sugeridos, seguindo }

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final PageController _pageController = PageController();
  FeedType _feedType = FeedType.sugeridos;
  int _currentIndex = 0;
  bool _showComments = false;
  bool _showActions = false;

  @override
  void initState() {
    super.initState();
    // Esconder barras do sistema para experiência imersiva
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  void _toggleLike(VideoModel video) {
    // Optimistic UI Update
    setState(() {
      video.isLiked = !video.isLiked;
    });
    
    // API Call
    ref.read(interactionRepositoryProvider).likeVideo(video.id).catchError((e) {
      // Revert on error
      if (mounted) {
        setState(() {
          video.isLiked = !video.isLiked;
        });
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Erro ao curtir: $e')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedControllerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Feed de vídeos (PageView horizontal)
          feedState.when(
            data: (videos) {
              if (videos.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhum vídeo encontrado',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              return PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.horizontal,
                itemCount: videos.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                  
                  // Carregar mais vídeos ao chegar perto do fim
                  if (index >= videos.length - 2) {
                    ref.read(feedControllerProvider.notifier).loadMore();
                  }
                },
                itemBuilder: (context, index) {
                  final video = videos[index];
                  return VideoCard(
                    video: video,
                    isActive: index == _currentIndex,
                    onLike: () => _toggleLike(video),
                    onComment: () {
                      ref.read(commentsControllerProvider.notifier).loadComments(video.id);
                      setState(() => _showComments = true);
                    },
                    onShare: () => setState(() => _showActions = true),
                    onUserTap: () {
                      context.push('/profile/${video.user.id}');
                    },
                    onTap: () {
                       Navigator.of(context).push(
                         MaterialPageRoute(builder: (context) => VideoDetailScreen(video: video)),
                       );
                    },
                    onSwipeUp: () {
                       ref.read(commentsControllerProvider.notifier).loadComments(video.id);
                       setState(() => _showComments = true);
                    },

                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: RhemaColors.gold),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar vídeos',
                    style: TextStyle(color: Colors.white),
                  ),
                  TextButton(
                    onPressed: () => ref.refresh(feedControllerProvider),
                    child: const Text('Tentar novamente'),
                  )
                ],
              ),
            ),
          ),

          // Top Bar (Navegação)
          _buildTopBar(),

          // Bottom Sheet de Comentários
          if (_showComments) _buildCommentsDrawer(),

          // Bottom Sheet de Ações
          if (_showActions) _buildActionsDrawer(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Busca
                IconButton(
                  onPressed: () => context.push('/search'),
                  icon: const Icon(Icons.search, color: Colors.white, size: 28),
                ),

                // Tabs do Feed
                Row(
                  children: [
                    _FeedTab(
                      label: 'Seguindo',
                      isActive: _feedType == FeedType.seguindo,
                      onTap: () {
                         setState(() => _feedType = FeedType.seguindo);
                         // TODO: Atualizar provider com filtro
                      },
                    ),
                    Container(
                      width: 1,
                      height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: Colors.white24,
                    ),
                    _FeedTab(
                      label: 'Sugeridos',
                      isActive: _feedType == FeedType.sugeridos,
                      onTap: () {
                         setState(() => _feedType = FeedType.sugeridos);
                         // TODO: Atualizar provider com filtro
                      },
                    ),
                  ],
                ),

                // Ações (Upload e Perfil)
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.push('/upload'),
                      icon: const Icon(Icons.add_circle_outline,
                          color: Colors.white, size: 28),
                    ),
                    IconButton(
                      onPressed: () => context.push('/profile'),
                      icon: const Icon(Icons.person_outline,
                          color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsDrawer() {
    final commentsState = ref.watch(commentsControllerProvider);
    final commentsController = ref.read(commentsControllerProvider.notifier);
    final TextEditingController _commentInputController = TextEditingController();

    return GestureDetector(
      onTap: () => setState(() => _showComments = false),
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {}, // Prevenir fechamento ao tocar no drawer
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: const BoxDecoration(
                color: RhemaColors.cardBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Título
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Comentários',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _showComments = false),
                          icon: const Icon(Icons.close, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12),
                  
                  // Lista de comentários
                  Expanded(
                    child: commentsState.isLoading
                        ? const Center(child: CircularProgressIndicator(color: RhemaColors.gold))
                        : commentsState.comments.isEmpty
                            ? const Center(
                                child: Text("Sem comentários ainda. Seja o primeiro!",
                                    style: TextStyle(color: Colors.white54)))
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: commentsState.comments.length,
                                itemBuilder: (context, index) {
                                  final comment = commentsState.comments[index];
                                  final user = comment['user'];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundImage: user['avatar'] != null 
                                            ? NetworkImage(user['avatar']) 
                                            : null,
                                          child: user['avatar'] == null 
                                            ? Text(user['name'][0].toUpperCase()) 
                                            : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user['handle'],
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                comment['text'],
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                DateFormat('dd/MM • HH:mm').format(DateTime.parse(comment['createdAt'])),
                                                style: TextStyle(color: Colors.white38, fontSize: 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            Icon(Icons.favorite_border, size: 16, color: Colors.white54),
                                            Text(
                                              comment['likesCount'].toString(),
                                              style: TextStyle(color: Colors.white54, fontSize: 10),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),

                  // Input de comentário
                  Container(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16, // Padding teclado
                      top: 8,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.white12)),
                      color: RhemaColors.cardBackground, 
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: RhemaColors.primary600,
                          child: Icon(Icons.person, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _commentInputController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Adicione um comentário...',
                              hintStyle: TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                              filled: true,
                              fillColor: Colors.white10,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                             if (_commentInputController.text.isNotEmpty) {
                               commentsController.postComment(_commentInputController.text);
                               _commentInputController.clear();
                               FocusScope.of(context).unfocus();
                             }
                          },
                          icon: Icon(Icons.send, color: RhemaColors.gold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Same logic for comment items

  Widget _buildActionsDrawer() {
    return GestureDetector(
      onTap: () => setState(() => _showActions = false),
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: const BoxDecoration(
                color: RhemaColors.cardBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionItem(Icons.link, 'Copiar Link'),
                      _buildActionItem(Icons.share, 'WhatsApp'),
                      _buildActionItem(Icons.download, 'Salvar'),
                      _buildActionItem(Icons.bookmark_border, 'Favoritar'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionItem(Icons.flag_outlined, 'Denunciar'),
                      _buildActionItem(Icons.not_interested, 'Não tenho interesse'),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _FeedTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FeedTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 16,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          color: isActive ? Colors.white : Colors.white60,
        ),
        child: Text(label),
      ),
    );
  }
}
