import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhema_app/features/feed/data/repositories/interaction_repository.dart';

// State
class CommentsState {
  final bool isLoading;
  final List<Map<String, dynamic>> comments;
  final String? error;

  CommentsState({
    this.isLoading = false,
    this.comments = const [],
    this.error,
  });

  CommentsState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? comments,
    String? error,
  }) {
    return CommentsState(
      isLoading: isLoading ?? this.isLoading,
      comments: comments ?? this.comments,
      error: error,
    );
  }
}

// Controller
class CommentsController extends StateNotifier<CommentsState> {
  final InteractionRepository _repository;
  String? _currentVideoId;

  CommentsController(this._repository) : super(CommentsState());

  Future<void> loadComments(String videoId) async {
    _currentVideoId = videoId;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final comments = await _repository.getComments(videoId);
      state = state.copyWith(isLoading: false, comments: comments);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> postComment(String text) async {
    if (_currentVideoId == null) {
      print('❌ CommentsController: videoId é null!');
      throw Exception('ID do vídeo não definido');
    }
    if (text.trim().isEmpty) {
      print('❌ CommentsController: texto vazio!');
      return;
    }

    print('📝 CommentsController: Enviando para videoId: $_currentVideoId');
    
    try {
      final newComment = await _repository.postComment(
        videoId: _currentVideoId!,
        text: text,
      );
      
      print('✅ CommentsController: Comentário criado: $newComment');
      
      // Adicionar comentário no topo da lista
      state = state.copyWith(
        comments: [newComment, ...state.comments],
      );
    } catch (e) {
      print('❌ CommentsController: Erro ao postar: $e');
      state = state.copyWith(error: e.toString());
      rethrow; // Propagar o erro para a UI
    }
  }
}

final commentsControllerProvider = StateNotifierProvider<CommentsController, CommentsState>((ref) {
  final repository = ref.watch(interactionRepositoryProvider);
  return CommentsController(repository);
});
