class VideoModel {
  final String id;
  final String type;
  final String videoUrl;
  final String? thumbnailUrl;
  final String? hlsUrl;
  final String? title;
  final String? description;
  final List<String> tags;
  final int? duration;
  final int likes;
  final int comments;
  final int shares;
  final String views;
  final UserShortModel user;
  final String? postedAt;
  final bool isAd;
  final String? parentVideoId;
  final ParentVideoInfo? parentVideo;
  
  // Local state
  bool isLiked;

  VideoModel({
    required this.id,
    this.type = 'SHORT',
    required this.videoUrl,
    this.thumbnailUrl,
    this.hlsUrl,
    this.title,
    this.description,
    this.tags = const [],
    this.duration,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.views = '0',
    required this.user,
    this.postedAt,
    this.isAd = false,
    this.isLiked = false,
    this.parentVideoId,
    this.parentVideo,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'SHORT',
      videoUrl: json['videoUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      hlsUrl: json['hlsUrl'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      duration: json['duration'] as int?,
      likes: json['likes'] as int? ?? 0,
      comments: json['comments'] as int? ?? 0,
      shares: json['shares'] as int? ?? 0,
      views: json['views']?.toString() ?? '0',
      user: UserShortModel.fromJson(json['user'] as Map<String, dynamic>),
      postedAt: json['postedAt'] as String?,
      isAd: json['isAd'] as bool? ?? false,
      isLiked: json['isLiked'] as bool? ?? false,
      parentVideoId: json['parentVideoId'] as String?,
      parentVideo: json['parentVideo'] != null 
          ? ParentVideoInfo.fromJson(json['parentVideo'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'hlsUrl': hlsUrl,
      'title': title,
      'description': description,
      'tags': tags,
      'duration': duration,
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'views': views,
      'user': user.toJson(),
      'postedAt': postedAt,
      'isAd': isAd,
      'isLiked': isLiked,
      'parentVideoId': parentVideoId,
      'parentVideo': parentVideo?.toJson(),
    };
  }
}

class UserShortModel {
  final String id;
  final String name;
  final String handle;
  final String? avatar;
  final bool isVerified;

  UserShortModel({
    required this.id,
    required this.name,
    required this.handle,
    this.avatar,
    this.isVerified = false,
  });

  factory UserShortModel.fromJson(Map<String, dynamic> json) {
    return UserShortModel(
      id: json['id'] as String,
      name: json['name'] as String,
      handle: json['handle'] as String,
      avatar: json['avatar'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'handle': handle,
      'avatar': avatar,
      'isVerified': isVerified,
    };
  }
}

class ParentVideoInfo {
  final String id;
  final String videoUrl;
  final String? thumbnailUrl;
  final String? title;
  final String? description;
  final int? duration;

  ParentVideoInfo({
    required this.id,
    required this.videoUrl,
    this.thumbnailUrl,
    this.title,
    this.description,
    this.duration,
  });

  factory ParentVideoInfo.fromJson(Map<String, dynamic> json) {
    return ParentVideoInfo(
      id: json['id'] as String,
      videoUrl: json['videoUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      duration: json['duration'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'title': title,
      'description': description,
      'duration': duration,
    };
  }
}
