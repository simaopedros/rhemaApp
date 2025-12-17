import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhema_app/core/constants/constants.dart';
import 'package:rhema_app/core/network/api_client.dart';
import 'package:rhema_app/features/profile/data/models/user_profile_model.dart';
import 'package:rhema_app/features/feed/data/models/video_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ProfileRepository(dio);
});

class ProfileRepository {
  final Dio _dio;

  ProfileRepository(this._dio);

  Future<UserProfileModel> getProfile(String? userId) async {
    try {
      // Se userId for null ou 'me', busca o perfil do usuário logado via /auth/me
      if (userId == null || userId == 'me') {
        final response = await _dio.get(ApiConstants.authMe);
        
        if (response.data['success'] == true && response.data['user'] != null) {
          return UserProfileModel.fromJson(response.data['user']);
        }
        throw Exception('Usuário não encontrado');
      }
      
      // Caso contrário, busca o perfil de outro usuário
      final response = await _dio.get('${ApiConstants.users}/$userId');
      
      if (response.data['success'] == true && response.data['user'] != null) {
        return UserProfileModel.fromJson(response.data['user']);
      }
      throw Exception('Usuário não encontrado');
    } on DioException catch (e) {
      print('❌ Profile API Error: ${e.response?.statusCode} - ${e.message}');
      if (e.response?.statusCode == 401) {
        throw Exception('Não autenticado. Faça login novamente.');
      }
      rethrow;
    }
  }

  Future<List<VideoModel>> getUserVideos(String userId) async {
    try {
      final response = await _dio.get('${ApiConstants.users}/$userId/videos');
      
      if (response.data['success'] == true) {
        final List<dynamic> list = response.data['videos'] ?? [];
        return list.map((e) => VideoModel.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      print('❌ User Videos API Error: ${e.message}');
      return [];
    }
  }
}

