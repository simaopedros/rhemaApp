import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rhema_app/core/constants/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rhema_app/core/theme/app_theme.dart';
import 'package:rhema_app/features/feed/data/models/video_model.dart';
import 'package:rhema_app/features/feed/data/services/video_preload_service.dart';
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
  final VideoPreloadService _preloadService = VideoPreloadService();
  int _currentIndex = 0;
  bool _showComments = false;
  bool _showActions = false;
  FeedType _currentFeedType = FeedType.sugeridos;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _preloadService.disposeAll();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  /// Verifica autenticação antes de executar ação
  Future<void> _runWithAuth(VoidCallback action) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: StorageKeys.authToken);

    if (token != null) {
      action();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Faça login para interagir'),
            action: SnackBarAction(
              label: 'Entrar',
              onPressed: () => context.push('/login'),
            ),
          ),
        );
      }
    }
  }

  void _toggleLike(VideoModel video) async {
    final previousState = video.isLiked;
    final previousCount = video.likes;

    // Atualização otimista
    setState(() {
      video.isLiked = !video.isLiked;
      video.likes += video.isLiked ? 1 : -1;
    });

    try {
      await ref.read(interactionRepositoryProvider).likeVideo(video.id);
    } catch (e) {
      // Reverter em caso de erro
      if (mounted) {
        setState(() {
          video.isLiked = previousState;
          video.likes = previousCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao curtir: $e')),
        );
      }
    }
  }

  Widget _buildFeedTab(String label, FeedType type) {
    final isSelected = _currentFeedType == type;
    return GestureDetector(
      onTap: () {
        if (_currentFeedType == type) return;
        setState(() {
          _currentFeedType = type;
          _currentIndex = 0;
        });
        // Chamar o algoritmo correto no backend
        final feedType = type == FeedType.sugeridos ? 'sugeridos' : 'seguindo';
        ref.read(feedControllerProvider.notifier).setFeedType(feedType);
        _pageController.jumpToPage(0);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            width: isSelected ? 24 : 0,
            decoration: BoxDecoration(
              color: RhemaColors.gold,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedControllerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Feed de vídeos - INTEGRAÇÃO REAL
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

              print('🎬 DEBUG PROVIDER: Loaded ${videos.length} videos from API/Repo');

              return PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.horizontal,
                itemCount: videos.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                  // Registrar visualização para o algoritmo de recomendação
                  final video = videos[index];
                  ref.read(interactionRepositoryProvider).registerView(video.id);
                },
                itemBuilder: (context, index) {
                  final video = videos[index];
                  return VideoCard(
                    video: video,
                    isActive: index == _currentIndex,
                    onLike: () => _runWithAuth(() => _toggleLike(video)),
                    onComment: () => _runWithAuth(() {
                      ref.read(commentsControllerProvider.notifier).loadComments(video.id);
                      setState(() => _showComments = true);
                    }),
                    onShare: () => _runWithAuth(() => setState(() => _showActions = true)),
                    onUserTap: () => context.push('/profile/${video.user.id}'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => VideoDetailScreen(video: video)),
                      );
                    },
                    onSwipeUp: () {
                      ref.read(commentsControllerProvider.notifier).loadComments(video.id);
                      setState(() => _showComments = true);
                    },
                    onSwipeDown: () {
                      // Show stats or other action
                    },
                    onFollow: () => _runWithAuth(() async {
                      try {
                        await ref.read(interactionRepositoryProvider).followUser(video.user.id);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    }),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: RhemaColors.gold),
            ),
            error: (error, stack) {
              print('❌ DEBUG UI: Feed error: $error');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Erro ao carregar vídeos\n$error',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () => ref.refresh(feedControllerProvider),
                      child: const Text('Tentar novamente'),
                    )
                  ],
                ),
              );
            },
          ),

          // Top Bar com Tabs e Navegação
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  // Botão Buscar
                  GestureDetector(
                    onTap: () => context.push('/search'),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  
                  // Tabs Centrais
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFeedTab('Seguindo', FeedType.seguindo),
                        const SizedBox(width: 24),
                        _buildFeedTab('Para você', FeedType.sugeridos),
                      ],
                    ),
                  ),
                  
                  // Botão Criar/Gravar Vídeo
                  GestureDetector(
                    onTap: () => context.push('/upload'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [RhemaColors.gold, Color(0xFFD4A853)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: RhemaColors.gold.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Botão Perfil
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Sheet de Comentários
          if (_showComments) _buildCommentsDrawer(),

          // Bottom Sheet de Ações
          if (_showActions) _buildActionsDrawer(),
        ],
      ),
    );
  }

  Widget _buildCommentsDrawer() {
    final commentsState = ref.watch(commentsControllerProvider);
    final feedState = ref.watch(feedControllerProvider);

    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _showComments = false),
        child: Container(
          color: Colors.black54,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping inside
              child: Container(
                height: MediaQuery.of(context).size.height * 0.6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Title
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Comentários (${commentsState.comments.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    // Comments List
                    Expanded(
                      child: commentsState.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : commentsState.comments.isEmpty
                              ? const Center(child: Text('Nenhum comentário ainda'))
                              : ListView.builder(
                                  itemCount: commentsState.comments.length,
                                  itemBuilder: (context, index) {
                                    final comment = commentsState.comments[index];
                                    return ListTile(
                                      leading: CircleAvatar(
                                        child: Text(
                                          (comment['user']?['name'] ?? 'A')[0],
                                        ),
                                      ),
                                      title: Text(comment['user']?['name'] ?? 'Anônimo'),
                                      subtitle: Text(comment['text'] ?? ''),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionsDrawer() {
    final feedState = ref.watch(feedControllerProvider);

    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _showActions = false),
        child: Container(
          color: Colors.black54,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Text(
                    'Compartilhar',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildShareOption(Icons.copy, 'Copiar Link'),
                      _buildShareOption(Icons.share, 'Mais'),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
