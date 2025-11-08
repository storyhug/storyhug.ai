class UserVoice {
  final String id;
  final String userId;
  final String voiceId; // ElevenLabs voice ID
  final String voiceName; // Custom name like "Mom", "Dad", "Grandma"
  final String? voiceDescription;
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserVoice({
    required this.id,
    required this.userId,
    required this.voiceId,
    required this.voiceName,
    this.voiceDescription,
    required this.isDefault,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserVoice.fromJson(Map<String, dynamic> json) {
    return UserVoice(
      id: json['id'],
      userId: json['user_id'],
      voiceId: json['voice_id'],
      voiceName: json['voice_name'],
      voiceDescription: json['voice_description'],
      isDefault: json['is_default'] ?? false,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'voice_id': voiceId,
      'voice_name': voiceName,
      'voice_description': voiceDescription,
      'is_default': isDefault,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper method to get display name
  String get displayName {
    return voiceName;
  }

  // Helper method to get full description
  String get fullDescription {
    if (voiceDescription != null && voiceDescription!.isNotEmpty) {
      return '$voiceName - $voiceDescription';
    }
    return voiceName;
  }

  // Helper method to check if this is a default voice
  bool get isDefaultVoice => isDefault;

  // Helper method to get creation date in readable format
  String get createdDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  // Copy with method for updates
  UserVoice copyWith({
    String? id,
    String? userId,
    String? voiceId,
    String? voiceName,
    String? voiceDescription,
    bool? isDefault,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserVoice(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      voiceId: voiceId ?? this.voiceId,
      voiceName: voiceName ?? this.voiceName,
      voiceDescription: voiceDescription ?? this.voiceDescription,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserVoice(id: $id, voiceName: $voiceName, isDefault: $isDefault)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserVoice && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
