import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhema_app/core/constants/constants.dart';
import 'package:rhema_app/core/network/api_client.dart';

final interactionRepositoryProvider = Provider<InteractionRepository>((ref) {
  return InteractionRepository(ref.read(dioProvider));
});

class InteractionRepository extends ApiService {
  InteractionRepository(super.dio);

  Future<bool> likeVideo(String videoId) async {
    try {
      final response = await dio.post(
        ApiConstants.interactionLike,
        data: {'videoId': videoId},
      );
      
      final data = response.data;
      if (data != null && data['success'] == false) {
        throw data['error'] ?? 'Erro desconhecido ao curtir';
      }
      
      return data['liked'] as bool;
    } on DioException catch (e) {
      throw handleError(e);
    } catch (e) {
       // Catch other errors (like the manual throw above)
       throw e.toString();
    }
  }

  Future<void> registerView(String videoId, {int? watchTime, int? duration}) async {
    try {
      await dio.post(
        ApiConstants.interactionView,
        data: {
          'videoId': videoId,
          'watchTime': watchTime ?? 0,
          'duration': duration ?? 0,
        },
      );
    } on DioException catch (e) {
      // Views failures normally fail silently
      print('Failed to register view: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> postComment({
    required String videoId,
    required String text,
    String? parentId,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.interactionComment,
        data: {
          'videoId': videoId,
          'text': text,
          'parentId': parentId,
        },
      );
      return response.data['comment'];
    } on DioException catch (e) {
      throw handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getComments(String videoId) async {
    try {
      final response = await dio.get('${ApiConstants.interactions}/comments/$videoId');
      return List<Map<String, dynamic>>.from(response.data['comments']);
    } on DioException catch (e) {
      throw handleError(e);
    }
  }

  Future<bool> saveVideo(String videoId) async {
    try {
      final response = await dio.post(
        ApiConstants.interactionSave,
        data: {'videoId': videoId},
      );
      
      final data = response.data;
      if (data != null && data['success'] == false) {
        throw data['error'] ?? 'Erro ao salvar vídeo';
      }
      
      return data['saved'] as bool? ?? true;
    } on DioException catch (e) {
      throw handleError(e);
    }
  }
}
