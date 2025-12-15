import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rhema_app/core/theme/app_theme.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _searchQuery = '';

  // Mock data
  final List<String> _trendingTags = [
    '#louvor',
    '#testemunho',
    '#devocional',
    '#biblia',
    '#igreja',
    '#adoracao',
    '#milagre',
    '#jesus',
    '#fe',
    '#oracao',
  ];

  final List<Map<String, dynamic>> _suggestedUsers = [
    {
      'id': 'u1',
      'name': 'Devocional Diário',
      'handle': '@devocional_hoje',
      'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
      'followers': '45k',
      'isVerified': true,
    },
    {
      'id': 'u2',
      'name': 'Pastora Helena',
      'handle': '@helena.pastora',
      'avatar': 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=100',
      'followers': '98k',
      'isVerified': true,
    },
    {
      'id': 'u3',
      'name': 'Lucas Guitar',
      'handle': '@lucas_worship',
      'avatar': 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?w=100',
      'followers': '8.2k',
      'isVerified': false,
    },
  ];

  final List<Map<String, dynamic>> _trendingVideos = [
    {
      'id': 'v1',
      'thumbnail': 'https://images.unsplash.com/photo-1438232992991-995b7058bbb3?w=400',
      'views': '45.2k',
      'description': 'A paz que excede todo entendimento',
    },
    {
      'id': 'v2',
      'thumbnail': 'https://images.unsplash.com/photo-1510936111840-65e151ad71bb?w=400',
      'views': '12.8k',
      'description': 'Louvor espontâneo',
    },
    {
      'id': 'v3',
      'thumbnail': 'https://images.unsplash.com/photo-1507692049790-de58293a469d?w=400',
      'views': '89.1k',
      'description': 'Estudo de Romanos 8',
    },
    {
      'id': 'v4',
      'thumbnail': 'https://images.unsplash.com/photo-1510590337019-5ef2d39aa7bf?w=400',
      'views': '1.2k',
      'description': 'Bom dia com fé',
    },
    {
      'id': 'v5',
      'thumbnail': 'https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=400',
      'views': '33.5k',
      'description': 'Nascer do sol glorioso',
    },
    {
      'id': 'v6',
      'thumbnail': 'https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?w=400',
      'views': '7.8k',
      'description': 'Retiro espiritual',
    },
  ];

  @override
  void initState() {
    super.initState();
    // _focusNode.requestFocus(); // Removed autofocus
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: _searchQuery.isEmpty ? _buildDiscoverContent() : _buildSearchResults(),
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
                  },
                  icon: Icon(Icons.close, color: Colors.white38, size: 20),
                )
              : null,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildDiscoverContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tags em alta
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
                  children: _trendingTags
                      .map((tag) => _buildTagChip(tag))
                      .toList(),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12),

          // Contas sugeridas
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
                ..._suggestedUsers.map((user) => _buildUserTile(user)),
              ],
            ),
          ),

          const Divider(color: Colors.white12),

          // Vídeos em alta
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
          _buildVideoGrid(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return GestureDetector(
      onTap: () => setState(() {
        _searchController.text = tag;
        _searchQuery = tag;
      }),
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

  Widget _buildUserTile(Map<String, dynamic> user) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/profile/${user['id']}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage: CachedNetworkImageProvider(user['avatar']),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (user['isVerified'] == true) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.verified, color: RhemaColors.gold, size: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${user['handle']} · ${user['followers']} seguidores',
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

  Widget _buildVideoGrid() {
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
      itemCount: _trendingVideos.length,
      itemBuilder: (context, index) {
        final video = _trendingVideos[index];
        return _buildVideoTile(video);
      },
    );
  }

  Widget _buildVideoTile(Map<String, dynamic> video) {
    return GestureDetector(
      onTap: () => context.push('/video/${video['id']}'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: video['thumbnail'],
                fit: BoxFit.cover,
              ),
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
                  Text(
                    video['description'],
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
                        video['views'],
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
    // Filtrar resultados pelo query
    final filteredUsers = _suggestedUsers
        .where((u) =>
            u['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
            u['handle'].toString().toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    final filteredVideos = _trendingVideos
        .where((v) =>
            v['description'].toString().toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

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
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 9 / 16,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: filteredVideos.length,
              itemBuilder: (context, index) => _buildVideoTile(filteredVideos[index]),
            ),
          ],
          if (filteredUsers.isEmpty && filteredVideos.isEmpty)
            Center(
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
            ),
        ],
      ),
    );
  }
}
