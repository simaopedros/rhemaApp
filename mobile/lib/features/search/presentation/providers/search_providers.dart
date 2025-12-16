import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/search_service.dart';
import '../../../feed/data/models/video_model.dart';
import '../../../profile/data/models/user_profile_model.dart';

// Provide the latest trending content
final trendingProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final service = ref.watch(searchServiceProvider);
  return service.getTrending();
});

// Holds the current search query
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

// Provides search results based on the query
final searchResultsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  
  // Don't search for empty or very short strings
  if (query.trim().length < 2) {
    return {
      'users': <UserProfileModel>[], 
      'videos': <VideoModel>[]
    };
  }
  
  // Use .read on service inside FutureProvider might be safer with .watch if service changes, 
  // but service is likely stable. .watch is safer.
  final service = ref.watch(searchServiceProvider);
  return service.search(query);
});
