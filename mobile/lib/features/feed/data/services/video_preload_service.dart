import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';

/// Serviço de cache para pré-carregamento de vídeos
/// Mantém os próximos vídeos já inicializados para reprodução instantânea
class VideoPreloadService {
  static final VideoPreloadService _instance = VideoPreloadService._internal();
  factory VideoPreloadService() => _instance;
  VideoPreloadService._internal();

  // Cache de controllers inicializados (URL -> Controller)
  final Map<String, VideoPlayerController> _cache = {};
  
  // Máximo de vídeos em cache (atual + próximos + anterior)
  static const int _maxCacheSize = 4;
  
  // URLs atualmente em processo de preload
  final Set<String> _loadingUrls = {};

  /// Obtém um controller do cache ou cria um novo
  /// Se já estiver inicializado, retorna imediatamente
  Future<VideoPlayerController?> getController(String videoUrl) async {
    // Se já está no cache e inicializado, retorna
    if (_cache.containsKey(videoUrl)) {
      final controller = _cache[videoUrl]!;
      if (controller.value.isInitialized) {
        debugPrint('📹 Cache HIT: $videoUrl');
        return controller;
      }
    }
    
    // Não está no cache, precisa criar
    debugPrint('📹 Cache MISS: $videoUrl - criando controller');
    return await _initializeController(videoUrl);
  }

  /// Pré-carrega uma lista de URLs (próximos vídeos)
  Future<void> preloadVideos(List<String> urls) async {
    for (final url in urls) {
      if (!_cache.containsKey(url) && !_loadingUrls.contains(url)) {
        _preloadSingle(url);
      }
    }
  }

  /// Pré-carrega um único vídeo em background
  Future<void> _preloadSingle(String url) async {
    if (_loadingUrls.contains(url)) return;
    
    _loadingUrls.add(url);
    debugPrint('⏳ Preloading: $url');
    
    try {
      await _initializeController(url);
      debugPrint('✅ Preloaded: $url');
    } catch (e) {
      debugPrint('❌ Preload failed: $url - $e');
    } finally {
      _loadingUrls.remove(url);
    }
  }

  /// Inicializa um controller e adiciona ao cache
  Future<VideoPlayerController?> _initializeController(String url) async {
    // Limpar cache se estiver cheio
    _cleanupCache();
    
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      
      await controller.initialize();
      controller.setLooping(true);
      
      // Pausar e posicionar no início (pronto para tocar)
      await controller.pause();
      await controller.seekTo(Duration.zero);
      
      _cache[url] = controller;
      return controller;
    } catch (e) {
      debugPrint('Erro ao inicializar vídeo: $e');
      return null;
    }
  }

  /// Remove controllers antigos quando o cache está cheio
  void _cleanupCache() {
    if (_cache.length >= _maxCacheSize) {
      // Remove o primeiro (mais antigo) que não está em uso
      final keysToRemove = <String>[];
      
      for (final entry in _cache.entries) {
        if (!entry.value.value.isPlaying && keysToRemove.length < 2) {
          keysToRemove.add(entry.key);
        }
      }
      
      for (final key in keysToRemove) {
        debugPrint('🗑️ Removendo do cache: $key');
        _cache[key]?.dispose();
        _cache.remove(key);
      }
    }
  }

  /// Para um vídeo específico
  void pause(String url) {
    _cache[url]?.pause();
  }

  /// Toca um vídeo específico
  Future<void> play(String url) async {
    final controller = _cache[url];
    if (controller != null && controller.value.isInitialized) {
      await controller.play();
    }
  }

  /// Reseta a posição de um vídeo
  Future<void> reset(String url) async {
    final controller = _cache[url];
    if (controller != null) {
      await controller.seekTo(Duration.zero);
    }
  }

  /// Verifica se um vídeo está no cache e inicializado
  bool isReady(String url) {
    return _cache.containsKey(url) && _cache[url]!.value.isInitialized;
  }

  /// Obtém o controller diretamente (sem await)
  VideoPlayerController? getCachedController(String url) {
    return _cache[url];
  }

  /// Limpa todo o cache (usar ao sair da tela)
  void disposeAll() {
    for (final controller in _cache.values) {
      controller.dispose();
    }
    _cache.clear();
    _loadingUrls.clear();
    debugPrint('🧹 Cache de vídeos limpo');
  }
}
