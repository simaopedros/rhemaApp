import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rhema_app/features/feed/data/models/video_model.dart';
import 'package:rhema_app/features/profile/data/models/user_profile_model.dart';
import 'package:rhema_app/features/profile/data/repositories/profile_repository.dart';

class ProfileState {
  final bool isLoading;
  final UserProfileModel? user;
  final List<VideoModel> videos;
  final String? error;

  ProfileState({
    this.isLoading = false,
    this.user,
    this.videos = const [],
    this.error,
  });

  ProfileState copyWith({
    bool? isLoading,
    UserProfileModel? user,
    List<VideoModel>? videos,
    String? error,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      videos: videos ?? this.videos,
      error: error,
    );
  }
}

class ProfileController extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;

  ProfileController(this._repository) : super(ProfileState());

  Future<void> loadProfile(String? userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 1. Get User Info
      final user = await _repository.getProfile(userId);
      state = state.copyWith(user: user);

      // 2. Get Videos (using the ID returned from profile, in case userId was null/'me')
      if (user != null) {
        final videos = await _repository.getUserVideos(user.id);
        state = state.copyWith(
          isLoading: false, 
          videos: videos
        );
      } else {
        state = state.copyWith(isLoading: false, error: 'Usuário não encontrado');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// Family provider to support multiple profiles (passing userId)
// AutoDispose to clear state when leaving screen
final profileControllerProvider = StateNotifierProvider.family.autoDispose<ProfileController, ProfileState, String?>(
  (ref, userId) {
    final repository = ref.watch(profileRepositoryProvider);
    final controller = ProfileController(repository);
    controller.loadProfile(userId);
    return controller;
  },
);
