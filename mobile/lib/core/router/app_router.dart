import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rhema_app/features/auth/presentation/screens/auth_screen.dart';
import 'package:rhema_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:rhema_app/features/feed/presentation/screens/feed_screen.dart'; // Mantido para referência futura
import 'package:rhema_app/features/feed/presentation/screens/feed_screen_v2.dart';
import 'package:rhema_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:rhema_app/features/search/presentation/screens/search_screen.dart';
import 'package:rhema_app/features/upload/presentation/screens/upload_screen.dart';
import 'package:rhema_app/features/video/presentation/screens/video_player_screen.dart';
import 'package:rhema_app/features/feed/data/models/video_model.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // Splash / Loading Screen
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Autenticação
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      
      // Feed Principal (V2 - Mockado)
      GoRoute(
        path: '/feed',
        name: 'feed',
        builder: (context, state) => const FeedScreenV2(),
      ),
      
      // Busca
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      
      // Upload
      GoRoute(
        path: '/upload',
        name: 'upload',
        builder: (context, state) => const UploadScreen(),
      ),
      
      // Perfil
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/:userId',
        name: 'userProfile',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return ProfileScreen(userId: userId);
        },
      ),
      
      // Player de Vídeo (horizontal para vídeos longos)
      GoRoute(
        path: '/video/:videoId',
        name: 'video',
        builder: (context, state) {
          final videoId = state.pathParameters['videoId']!;
          final video = state.extra as VideoModel?;
          return VideoPlayerScreen(videoId: videoId, video: video);
        },
      ),
    ],
    
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Página não encontrada',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/feed'),
              child: const Text('Voltar ao início'),
            ),
          ],
        ),
      ),
    ),
  );
});
