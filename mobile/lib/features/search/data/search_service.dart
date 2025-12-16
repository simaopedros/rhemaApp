import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../feed/data/models/video_model.dart';
import '../../profile/data/models/user_profile_model.dart';

final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService(ref.read(dioProvider));
});

class SearchService extends ApiService {
  SearchService(super.dio);

  Future<Map<String, dynamic>> search(String query) async {
    try {
      final response = await dio.get(
        '/search',
        queryParameters: {'q': query},
      );

      final data = response.data;
      
      final users = (data['users'] as List)
          .map((e) => UserProfileModel.fromJson(e))
          .toList();
          
      final videos = (data['videos'] as List)
          .map((e) => VideoModel.fromJson(e))
          .toList();

      return {
        'users': users,
        'videos': videos,
      };
    } on DioException catch (e) {
      return _getMockData();
    }
  }

  Future<Map<String, dynamic>> getTrending() async {
    try {
      final response = await dio.get('/search/trending');
      final data = response.data;

      final tags = List<String>.from(data['trendingTags']);
      
      final popularUsers = (data['popularUsers'] as List)
          .map((e) => UserProfileModel.fromJson(e))
          .toList();
          
      final trendingVideos = (data['trendingVideos'] as List)
          .map((e) => VideoModel.fromJson(e))
          .toList();

      return {
        'tags': tags,
        'users': popularUsers,
        'videos': trendingVideos,
      };
    } on DioException catch (e) {
      return _getMockData(isTrending: true);
    }
  }

  Map<String, dynamic> _getMockData({bool isTrending = false}) {
    final mockUser = UserProfileModel(
       id: 'u1', name: 'Padre Marcelo', handle: '@padremarcelo', isVerified: true, 
       bio: 'Sacerdote Católico', avatar: 'https://i.pravatar.cc/200?img=1',
       followersCount: 1000, followingCount: 10, videosCount: 12
    );

    final mockVideo = VideoModel(
        id: '1',
        title: 'Benção do Dia',
        description: 'Paz e Bem!',
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
        thumbnailUrl: 'https://picsum.photos/seed/v1/400/600',
        user: UserShortModel(id: 'u1', name: 'Padre Marcelo', handle: '@padremarcelo', avatar: 'https://i.pravatar.cc/200?img=1', isVerified: true),
        likes: 1540, comments: 120, shares: 500, views: '12.4k', isLiked: false, tags: ['catolico']
    );

    if (isTrending) {
      return {
        'tags': ['#louvor', '#culto', '#missa', '#pregacao'],
        'users': [mockUser],
        'videos': [mockVideo],
      };
    } else {
      return {
        'users': [mockUser],
        'videos': [mockVideo],
      };
    }
  }
}
