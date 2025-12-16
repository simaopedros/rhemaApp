import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhema_app/core/theme/app_theme.dart';
import 'package:rhema_app/features/feed/presentation/providers/comments_controller.dart';

class CommentsDrawer extends ConsumerStatefulWidget {
  final String videoId;
  final VoidCallback onClose;

  const CommentsDrawer({
    super.key,
    required this.videoId,
    required this.onClose,
  });

  @override
  ConsumerState<CommentsDrawer> createState() => _CommentsDrawerState();
}

class _CommentsDrawerState extends ConsumerState<CommentsDrawer> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Carregar comentários ao abrir (se não estiverem carregados)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(commentsControllerProvider.notifier).loadComments(widget.videoId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _postComment() {
    final text = _commentController.text.trim();
    if (text.isNotEmpty) {
      ref.read(commentsControllerProvider.notifier).postComment(text);
      _commentController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(commentsControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text(
                   'Comentários (${state.comments.length})',
                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                 ),
                 IconButton(
                   icon: const Icon(Icons.close),
                   onPressed: widget.onClose,
                 )
              ],
            ),
          ),
          const Divider(height: 1),

          // Lista de Comentários
          Expanded(
            child: state.isLoading
              ? const Center(child: CircularProgressIndicator(color: RhemaColors.gold))
              : state.comments.isEmpty
                  ? Center(child: Text('Nenhum comentário ainda. Seja o primeiro!', style: TextStyle(color: Colors.grey[500])))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.comments.length,
                      itemBuilder: (context, index) {
                        final comment = state.comments[index];
                        // Safe access
                        final userName = comment['user_name'] ?? 'Usuário';
                        final userAvatar = comment['user_avatar'];
                        final text = comment['text'] ?? '';
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: userAvatar != null ? CachedNetworkImageProvider(userAvatar) : null,
                                backgroundColor: Colors.grey[300],
                                child: userAvatar == null ? const Icon(Icons.person, color: Colors.grey) : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          userName,
                                          style: TextStyle(
                                            color: isDark ? Colors.grey[300] : Colors.grey[800],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'há pouco', 
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      text,
                                      style: TextStyle(
                                        color: isDark ? Colors.white : Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Like no comentário
                              const Icon(Icons.favorite_border, size: 16, color: Colors.grey),
                            ],
                          ),
                        );
                      },
                    ),
          ),

          // Input de Comentário
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey, // Placeholder user current
                  child: Icon(Icons.person, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Adicione um comentário...',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onSubmitted: (_) => _postComment(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: RhemaColors.gold),
                  onPressed: _postComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
