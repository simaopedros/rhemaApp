class UserProfileModel {
  final String id;
  final String name;
  final String handle;
  final String? avatar;
  final String? bio;
  final int followersCount;
  final int followingCount;
  final int videosCount;
  final bool isVerified;

  UserProfileModel({
    required this.id,
    required this.name,
    required this.handle,
    this.avatar,
    this.bio,
    this.followersCount = 0,
    this.followingCount = 0,
    this.videosCount = 0,
    this.isVerified = false,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      handle: json['handle'] as String,
      avatar: json['avatar'] as String?,
      bio: json['bio'] as String?,
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      videosCount: json['videosCount'] as int? ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }
}
