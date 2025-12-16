import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rhema_app/core/theme/app_theme.dart';

import '../../../feed/data/models/video_model.dart';
import '../../../profile/data/models/user_profile_model.dart';
import '../providers/search_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sync local query with provider if needed, or just use local for UI instant feedback 
    // and push to provider for API
    
    return Scaffold(
      backgroundColor: RhemaColors.feedBackground,
      appBar: AppBar(
        backgroundColor: RhemaColors.cardBackground,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: _buildSearchField(),
        titleSpacing: 0,
      ),
      body: _searchQuery.isEmpty 
          ? _buildDiscoverContent() 
          : _buildSearchResults(),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 42,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Pesquisar...',
          hintStyle: TextStyle(color: Colors.white38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          prefixIcon: Icon(Icons.search, color: Colors.white38, size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    ref.read(searchQueryProvider.notifier).state = '';
                  },
                  icon: Icon(Icons.close, color: Colors.white38, size: 20),
                )
              : null,
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
          // Debounce could be good here, but for now direct update
          ref.read(searchQueryProvider.notifier).state = value;
        },
      ),
    );
  }

  Widget _buildDiscoverContent() {
    final trendingAsync = ref.watch(trendingProvider);

    return trendingAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: RhemaColors.gold),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar conteúdo',
              style: TextStyle(color: Colors.white54),
            ),
            TextButton(
              onPressed: () => ref.refresh(trendingProvider),
              child: const Text('Tentar novamente', style: TextStyle(color: RhemaColors.gold)),
            ),
          ],
        ),
      ),
      data: (data) {
        final tags = data['tags'] as List<String>;
        final users = data['users'] as List<UserProfileModel>;
        final videos = data['videos'] as List<VideoModel>;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tags em alta
              if (tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Em alta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tags
                            .map((tag) => _buildTagChip(tag))
                            .toList(),
                      ),
                    ],
                  ),
                ),

              if (tags.isNotEmpty && users.isNotEmpty)
                const Divider(color: Colors.white12),

              // Contas sugeridas
              if (users.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contas populares',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...users.map((user) => _buildUserTile(user)),
                    ],
                  ),
                ),

              if (users.isNotEmpty && videos.isNotEmpty)
                const Divider(color: Colors.white12),

              // Vídeos em alta
              if (videos.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: const Text(
                    'Vídeos populares',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _buildVideoGrid(videos),
                const SizedBox(height: 32),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTagChip(String tag) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _searchController.text = tag;
          _searchQuery = tag;
        });
        ref.read(searchQueryProvider.notifier).state = tag;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: RhemaColors.primary800,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: RhemaColors.gold.withOpacity(0.3)),
        ),
        child: Text(
          tag,
          style: TextStyle(
            color: RhemaColors.gold,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildUserTile(UserProfileModel user) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/profile/${user.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage: user.avatar != null
                    ? CachedNetworkImageProvider(user.avatar!)
                    : null,
                child: user.avatar == null ? const Icon(Icons.person, color: Colors.white) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (user.isVerified) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.verified, color: RhemaColors.gold, size: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${user.handle} · ${user.followersCount} seguidores',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Seguir',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoGrid(List<VideoModel> videos) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 9 / 16,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return _buildVideoTile(video);
      },
    );
  }

  Widget _buildVideoTile(VideoModel video) {
    return GestureDetector(
      onTap: () => context.push('/video/${video.id}'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: video.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: video.thumbnailUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.white10),
                      errorWidget: (context, url, error) => Container(color: Colors.white10),
                    )
                  : Container(color: Colors.black),
            ),
            // Gradiente
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Info
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (video.description != null)
                    Text(
                      video.description!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.play_arrow, color: Colors.white70, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        video.views,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final searchAsync = ref.watch(searchResultsProvider);

    return searchAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: RhemaColors.gold),
      ),
      error: (error, stack) => Center(
        child: Text(
          'Erro na busca',
          style: TextStyle(color: Colors.white54),
        ),
      ),
      data: (data) {
        final filteredUsers = data['users'] as List<UserProfileModel>;
        final filteredVideos = data['videos'] as List<VideoModel>;

        if (filteredUsers.isEmpty && filteredVideos.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum resultado para "$_searchQuery"',
                    style: TextStyle(color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (filteredUsers.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...filteredUsers.map((user) => _buildUserTile(user)),
                    ],
                  ),
                ),
              ],
              if (filteredVideos.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Text(
                    'Vídeos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _buildVideoGrid(filteredVideos),
              ],
            ],
          ),
        );
      },
    );
  }
}
