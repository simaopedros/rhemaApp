import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rhema_app/core/theme/app_theme.dart';
import 'package:rhema_app/features/profile/presentation/providers/profile_controller.dart';
import 'package:rhema_app/features/auth/data/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rhema_app/core/constants/constants.dart';
import 'package:rhema_app/features/feed/data/models/video_model.dart';
import 'package:rhema_app/features/profile/data/models/user_profile_model.dart';
import 'package:rhema_app/features/feed/data/repositories/interaction_repository.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isOwnProfile => widget.userId == null || widget.userId == 'me';

  Future<void> _handleLogout() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      
      // Limpar token do storage
      const storage = FlutterSecureStorage();
      await storage.delete(key: StorageKeys.authToken);
      await storage.delete(key: StorageKeys.userId);
      
      if (mounted) {
        context.go('/auth');
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
           SnackBar(content: Text('Erro ao sair: $e')),
        );
      }
    }
  }

  Future<void> _toggleFollow(String userId) async {
    final previousState = _isFollowing;
    setState(() => _isFollowing = !_isFollowing);
    
    try {
      final repo = ref.read(interactionRepositoryProvider);
      if (_isFollowing) {
        await repo.followUser(userId);
      } else {
        await repo.unfollowUser(userId);
      }
    } catch (e) {
      // Reverter em caso de erro
      if (mounted) {
        setState(() => _isFollowing = previousState);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider(widget.userId));
    final user = state.user;

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: RhemaColors.feedBackground,
        body: Center(child: CircularProgressIndicator(color: RhemaColors.gold)),
      );
    }

    if (state.error != null || user == null) {
      return Scaffold(
        backgroundColor: RhemaColors.feedBackground,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white54, size: 48),
              const SizedBox(height: 16),
              Text(
                state.error ?? 'Erro ao carregar perfil',
                style: const TextStyle(color: Colors.white),
              ),
              TextButton(
                onPressed: () => ref.refresh(profileControllerProvider(widget.userId)),
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: RhemaColors.primary50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: Text(
          user.handle,
          style: const TextStyle(
            color: RhemaColors.primary900,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isOwnProfile)
            IconButton(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, color: RhemaColors.error),
            ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: _buildProfileHeader(user, state.videos.length),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                tabController: _tabController,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildVideosGrid(state.videos),
            _buildLikedVideosGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserProfileModel user, int videoCount) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundImage: user.avatar != null 
                    ? CachedNetworkImageProvider(user.avatar!) 
                    : null,
                child: user.avatar == null 
                    ? Text(user.name[0].toUpperCase(), style: const TextStyle(fontSize: 32, color: RhemaColors.primary900))
                    : null,
              ),
              if (user.isVerified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: RhemaColors.gold,
                      shape: BoxShape.circle,
                      border: Border.all(color: RhemaColors.primary50, width: 2),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Nome
          Text(
            user.name,
            style: const TextStyle(
              color: RhemaColors.primary900,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),

          // Bio
          if (user.bio != null)
            Text(
              user.bio!,
              style: const TextStyle(
                color: RhemaColors.primary600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 20),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStat(
                videoCount.toString(),
                'Vídeos',
              ),
              Container(
                width: 1,
                height: 30,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                color: RhemaColors.primary300,
              ),
              _buildStat(
                _formatNumber(user.followersCount),
                'Seguidores',
              ),
              Container(
                width: 1,
                height: 30,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                color: RhemaColors.primary300,
              ),
              _buildStat(
                _formatNumber(user.followingCount),
                'Seguindo',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Botões de ação
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isOwnProfile) ...[
                _buildActionButton(
                  'Editar Perfil',
                  Icons.edit,
                  isPrimary: false,
                  onTap: () {},
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  'Compartilhar',
                  Icons.share,
                  isPrimary: false,
                  onTap: () {},
                ),
              ] else ...[
                _buildActionButton(
                  _isFollowing ? 'Seguindo' : 'Seguir',
                  _isFollowing ? Icons.check : Icons.add,
                  isPrimary: !_isFollowing,
                  onTap: () => _toggleFollow(user.id),
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  'Mensagem',
                  Icons.mail_outline,
                  isPrimary: false,
                  onTap: () {},
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: RhemaColors.primary900,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: RhemaColors.primary500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon, {
    bool isPrimary = true,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isPrimary ? RhemaColors.gold : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isPrimary ? null : Border.all(color: RhemaColors.primary300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isPrimary ? Colors.black : RhemaColors.primary900,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.black : RhemaColors.primary900,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideosGrid(List<VideoModel> videos) {
    if (videos.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum vídeo publicado',
          style: TextStyle(color: RhemaColors.primary400),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 9 / 16,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return _buildVideoThumbnail(video);
      },
    );
  }

  Widget _buildLikedVideosGrid() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 48, color: RhemaColors.primary300),
          SizedBox(height: 16),
          Text(
            'Vídeos curtidos são privados',
            style: TextStyle(color: RhemaColors.primary400),
          ),
        ],
      ),
    );
  }

  // ... _buildVideoThumbnail kept mostly same but check icon colors if any overlay ...
  // Actually, video thumbnails have white text overlay on video image. That should remain WHITE for contrast.
  Widget _buildVideoThumbnail(VideoModel video) {
     return GestureDetector(
      onTap: () => context.push(
        '/video/${video.id}',
        extra: video,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: video.thumbnailUrl ?? video.videoUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: RhemaColors.primary200, // Light placeholder
            ),
            errorWidget: (_,__,___) => Container(color: Colors.grey[400]),
          ),
          
          Positioned(
            left: 4,
            bottom: 4,
            child: Row(
              children: [
                const Icon(
                  Icons.play_arrow,
                  color: Colors.white, // Keep white on image
                  size: 16,
                ),
                const SizedBox(width: 2),
                Text(
                  video.views,
                  style: const TextStyle(
                    color: Colors.white, // Keep white on image
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;

  _TabBarDelegate({required this.tabController});

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    return Container(
      color: RhemaColors.primary50, // Light background
      child: TabBar(
        controller: tabController,
        indicatorColor: RhemaColors.gold,
        indicatorWeight: 2,
        labelColor: RhemaColors.primary900,
        unselectedLabelColor: RhemaColors.primary500,
        tabs: const [
          Tab(icon: Icon(Icons.grid_on)),
          Tab(icon: Icon(Icons.favorite_border)),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
