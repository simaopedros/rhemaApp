import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhema_app/core/constants/constants.dart';
import 'package:rhema_app/features/feed/data/repositories/feed_repository.dart';

final interactionRepositoryProvider = Provider<InteractionRepository>((ref) {
  return InteractionRepository(Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: ApiConstants.connectTimeout,
    receiveTimeout: ApiConstants.receiveTimeout,
  )));
});

class InteractionRepository {
  final Dio _dio;

  InteractionRepository(this._dio);

  Future<void> likeVideo(String videoId) async {
    try {
      // TODO: Adicionar token nos headers quando auth estiver pronta
      // await _dio.post(ApiConstants.interactionLike, data: {'videoId': videoId});
      // Mock log
      print('Liked video $videoId (API call pending auth)');
    } catch (e) {
      throw Exception('Erro ao curtir vídeo: $e');
    }
  }

  Future<Map<String, dynamic>> postComment({
    required String videoId,
    required String text,
    String? parentId,
  }) async {
    try {
      // TODO: Usar endpoint real
      // final response = await _dio.post(ApiConstants.interactionComment, data: {
      //   'videoId': videoId,
      //   'text': text,
      //   'parentId': parentId,
      // });
      // return response.data;
      
      // MOCK RETURN
      await Future.delayed(const Duration(milliseconds: 500));
      return {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': text,
        'user': {
          'name': 'Você',
          'handle': '@voce',
          'avatar': null,
        },
        'createdAt': DateTime.now().toIso8601String(),
        'likesCount': 0,
      };
    } catch (e) {
      throw Exception('Erro ao enviar comentário: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getComments(String videoId) async {
    try {
      // TODO: Usar endpoint real
      // final response = await _dio.get('${ApiConstants.interactions}/comments/$videoId');
      // return List<Map<String, dynamic>>.from(response.data['comments']);
      
      // MOCK RETURN
      await Future.delayed(const Duration(milliseconds: 800));
      return [
        {
          'id': '1',
          'text': 'Glória a Deus! 🙌',
          'user': {'name': 'Maria Silva', 'handle': '@maria.s', 'avatar': null},
          'likesCount': 12,
          'createdAt': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        },
        {
          'id': '2',
          'text': 'Muito edificante esse vídeo.',
          'user': {'name': 'João Souza', 'handle': '@joao.z', 'avatar': null},
          'likesCount': 5,
          'createdAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        },
      ];
    } catch (e) {
      throw Exception('Erro ao buscar comentários: $e');
    }
  }
}
