import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhema_app/features/feed/data/models/video_model.dart';
import 'package:rhema_app/features/feed/data/repositories/feed_repository.dart';

final feedControllerProvider = AsyncNotifierProvider<FeedController, List<VideoModel>>(FeedController.new);

class FeedController extends AsyncNotifier<List<VideoModel>> {
  int _page = 1;
  bool _isLoadingMore = false;
  String _currentType = 'sugeridos';
  int _cycleCount = 0; // Quantas vezes já reiniciou o feed

  bool get isLoadingMore => _isLoadingMore;
  String get currentType => _currentType;

  @override
  FutureOr<List<VideoModel>> build() async {
    _page = 1;
    _cycleCount = 0;
    _currentType = 'sugeridos';
    return _fetchFeed(page: 1);
  }

  Future<void> setFeedType(String type) async {
    if (_currentType == type) return;
    _currentType = type;
    await refresh();
  }

  Future<List<VideoModel>> _fetchFeed({required int page}) async {
    final repository = ref.read(feedRepositoryProvider);
    final newVideos = await repository.getFeed(page: page, type: _currentType);
    return newVideos;
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || state.isLoading) return;

    _isLoadingMore = true;
    _page++;

    final currentVideos = state.value ?? [];
    
    try {
      final newVideos = await _fetchFeed(page: _page);
      
      if (newVideos.isEmpty) {
        // Se não tem mais vídeos novos, reinicia do início (feed infinito)
        _page = 1;
        _cycleCount++;
        final recycledVideos = await _fetchFeed(page: 1);
        // Adiciona os vídeos reciclados ao final da lista
        state = AsyncValue.data([...currentVideos, ...recycledVideos]);
      } else {
        state = AsyncValue.data([...currentVideos, ...newVideos]);
      }
    } catch (e, st) {
      _page--;
      state = AsyncValue.data(currentVideos);
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refresh() async {
    _page = 1;
    _cycleCount = 0;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchFeed(page: 1));
  }
}

