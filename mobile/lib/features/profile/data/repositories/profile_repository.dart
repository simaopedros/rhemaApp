import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhema_app/core/constants/constants.dart';
import 'package:rhema_app/features/profile/data/models/user_profile_model.dart';
import 'package:rhema_app/features/feed/data/models/video_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: ApiConstants.connectTimeout,
    receiveTimeout: ApiConstants.receiveTimeout,
    // TODO: Adicionar interceptor de Auth
  )));
});

class ProfileRepository {
  final Dio _dio;

  ProfileRepository(this._dio);

  Future<UserProfileModel> getProfile(String? userId) async {
    try {
      final endpoint = userId != null ? '/users/$userId' : '/users/me';
      
      // MOCK AUTH for 'me' until real auth state is global
      // Se for /me, precisaríamos do token. Como está mockado, vamos assumir
      // que o backend retornaria o usuário padrão se tivéssemos token.
      // MAS, como não temos token global ainda, o /me vai falhar sem header.
      // Sendo assim, para TESTE, vamos pegar um user fixo se for 'me' ou userId null.
      
      // UPDATE: Backend agora tem /users/me mas precisa de token.
      // Vamos tentar usar um ID fixo que sabemos que existe ou falhará.
      // Se userId for null, vamos tentar pegar o primeiro usuário ou usar mock.
      
      // TEMPORARY FIX: Se userId == null, assume mock user ID ou tenta /me com token fixo?
      // Vou tentar chamar a API e se falhar faço fallback para mock.
      
      final response = await _dio.get(endpoint, options: Options(
        headers: {
           // 'Authorization': 'Bearer ...' // TODO: Get from storage
        }
      ));
      
      return UserProfileModel.fromJson(response.data['user']);
    } catch (e) {
      // Fallback para Mock se der erro (ex: 401 Unauthorized no /me)
      print('Profile API Error: $e. Using mock data.');
      await Future.delayed(const Duration(milliseconds: 500));
      return UserProfileModel(
        id: userId ?? 'me',
        name: 'Usuário (Dev)',
        handle: '@usuario_dev',
        bio: 'Perfil em desenvolvimento', 
        avatar: 'https://ui-avatars.com/api/?name=U+D&background=random',
        isVerified: true,
        followersCount: 1205,
        followingCount: 340,
        videosCount: 0,
      );
    }
  }

  Future<List<VideoModel>> getUserVideos(String userId) async {
    try {
      // Mock ID fixo para teste se for 'me'
      final targetId = userId == 'me' ? 'mock_user_id' : userId; 
      
      final response = await _dio.get('/users/$targetId/videos');
      
      final List<dynamic> list = response.data['videos'];
      return list.map((e) => VideoModel.fromJson(e)).toList();
    } catch (e) {
      print('User Videos API Error: $e');
      // Fallback Mock
      await Future.delayed(const Duration(milliseconds: 800));
      return [];
    }
  }
}
