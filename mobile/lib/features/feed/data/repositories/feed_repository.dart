import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhema_app/core/constants/constants.dart';
import 'package:rhema_app/core/network/api_client.dart';
import 'package:rhema_app/features/feed/data/models/video_model.dart';
import 'dart:math';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return FeedRepository(dio);
});

class FeedRepository extends ApiService {
  FeedRepository(super.dio);

  Future<List<VideoModel>> getFeed({int page = 1, int limit = 10, String type = 'sugeridos'}) async {
    try {
      final response = await dio.get(
        ApiConstants.feed,
        queryParameters: {
          'page': page,
          'limit': limit,
          'type': type,
        },
      );

      final data = response.data;
      if (data['success'] == true) {
        final List videos = data['videos'];
        return videos.map((v) => VideoModel.fromJson(v)).toList();
      } else {
        throw Exception(data['error'] ?? 'Erro ao carregar vídeos');
      }
    } on DioException catch (e) {
      // Fallback para Mock Data se a API falhar (Modo Offline/Dev)
      print('⚠️ API Error: ${e.message}. Using Fallback Mock Data.');
      return _getMockVideos();
    } catch (e) {
       print('⚠️ Generic Error: $e. Using Fallback Mock Data.');
       return _getMockVideos();
    }
  }

  // Dados Mockados Diversificados (Católicos e Evangélicos)
  List<VideoModel> _getMockVideos() {
    return [
      VideoModel(
        id: '1',
        title: 'Benção do Dia',
        description: 'Que a paz de Cristo esteja em seus corações hoje e sempre. Amém! 🙏🕊️ #catolico #fé #benção',
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
        thumbnailUrl: 'https://picsum.photos/seed/v1/400/600',
        user: UserShortModel(
          id: 'u1',
          name: 'Padre Marcelo',
          handle: '@padremarcelo',
          avatar: 'https://i.pravatar.cc/200?img=1',
          isVerified: true,
        ),
        likes: 1540,
        comments: 120,
        shares: 500,
        views: '12.4k',
        isLiked: false,
        tags: ['catolico', 'oração', 'benção'],
      ),
      VideoModel(
        id: '2',
        title: 'Ressuscita-me - Ao Vivo',
        description: 'Um momento de adoração profunda. Nada é impossível para o nosso Deus! ✨🙌 #louvor #adoração #milagre',
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
        thumbnailUrl: 'https://picsum.photos/seed/v2/400/600',
        user: UserShortModel(
          id: 'u2',
          name: 'Aline Barros',
          handle: '@alinebarros',
          avatar: 'https://i.pravatar.cc/200?img=5',
          isVerified: true,
        ),
        likes: 3200,
        comments: 450,
        shares: 1200,
        views: '45k',
        isLiked: true,
        tags: ['louvor', 'musica', 'evangelico'],
      ),
      VideoModel(
        id: '3',
        title: 'Angelus no Vaticano',
        description: 'Uma mensagem de esperança para todos os povos. O amor vence o ódio. 🇻🇦❤️ #vaticano #papa #igreja',
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
        thumbnailUrl: 'https://picsum.photos/seed/v3/400/600',
        user: UserShortModel(
          id: 'u3',
          name: 'Papa Francisco',
          handle: '@pontifex_br',
          avatar: 'https://i.pravatar.cc/200?img=3',
          isVerified: true,
        ),
        likes: 50000,
        comments: 2000,
        shares: 15000,
        views: '200k',
        isLiked: false,
        tags: ['catolico', 'vaticano', 'papa'],
      ),
      VideoModel(
        id: '4',
        title: 'Não desista agora!',
        description: 'A sua vitória está mais perto do que você imagina. Escute essa palavra! 🔥📖 #pregação #motivação #fé',
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
        thumbnailUrl: 'https://picsum.photos/seed/v4/400/600',
        user: UserShortModel(
          id: 'u4',
          name: 'Deive Leonardo',
          handle: '@deiveleonardo',
          avatar: 'https://i.pravatar.cc/200?img=8',
          isVerified: true,
        ),
        likes: 8900,
        comments: 340,
        shares: 2100,
        views: '78k',
        isLiked: true,
        tags: ['evangelico', 'pregação', 'palavra'],
      ),
      VideoModel(
        id: '5',
        title: 'Acampamento Shalom',
        description: 'A alegria de ser de Deus! Juventude santa! ⛺🔥🎸 #shalom #juventude #catolico',
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
        thumbnailUrl: 'https://picsum.photos/seed/v5/400/600',
        user: UserShortModel(
          id: 'u5',
          name: 'Comunidade Shalom',
          handle: '@comshalom',
          avatar: 'https://i.pravatar.cc/200?img=12',
          isVerified: true,
        ),
        likes: 4100,
        comments: 230,
        shares: 400,
        views: '22k',
        isLiked: false,
        tags: ['catolico', 'jovens', 'shalom'],
      ),
    ];
  }
}
