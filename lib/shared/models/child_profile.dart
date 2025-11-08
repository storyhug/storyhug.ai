class ChildProfile {
  final String id;
  final String userId;
  final String childName;
  final int ageBucket;
  final String? avatarUrl;
  final String? nickname;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChildProfile({
    required this.id,
    required this.userId,
    required this.childName,
    required this.ageBucket,
    this.avatarUrl,
    this.nickname,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: json['id'],
      userId: json['user_id'],
      childName: json['child_name'],
      ageBucket: json['age_bucket'],
      avatarUrl: json['avatar_url'],
      nickname: json['nickname'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'child_name': childName,
      'age_bucket': ageBucket,
      'avatar_url': avatarUrl,
      'nickname': nickname,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  
  ChildProfile copyWith({
    String? id,
    String? userId,
    String? childName,
    int? ageBucket,
    String? avatarUrl,
    String? nickname,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      childName: childName ?? this.childName,
      ageBucket: ageBucket ?? this.ageBucket,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      nickname: nickname ?? this.nickname,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
