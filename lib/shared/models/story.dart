class Story {
  final String id;
  final String title;
  final String body;
  final String category;
  final int minAge;
  final int maxAge;
  final String audioDefaultUrl;
  final int durationMinutes;
  final String? thumbnailUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Story({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.minAge,
    required this.maxAge,
    required this.audioDefaultUrl,
    required this.durationMinutes,
    this.thumbnailUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      category: json['category'],
      minAge: json['min_age'],
      maxAge: json['max_age'],
      audioDefaultUrl: json['audio_default_url'],
      durationMinutes: json['duration_minutes'] ?? 5,
      thumbnailUrl: json['thumbnail_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'category': category,
      'min_age': minAge,
      'max_age': maxAge,
      'audio_default_url': audioDefaultUrl,
      'duration_minutes': durationMinutes,
      'thumbnail_url': thumbnailUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  
  // Helper method to check if story has audio content
  bool get hasAudioContent {
    return audioDefaultUrl.isNotEmpty && 
           audioDefaultUrl != 'null' &&
           !audioDefaultUrl.contains('placeholder') &&
           audioDefaultUrl.startsWith('http');
  }
  
  // Helper method to check if story is text-only
  bool get isTextOnly {
    return !hasAudioContent;
  }
  
  // Helper method to get content type
  String get contentType {
    return hasAudioContent ? 'Audio + Text' : 'Text Only';
  }
  
  // Helper method to check if story is suitable for age
  bool isSuitableForAge(int age) {
    return age >= minAge && age <= maxAge;
  }
  
  // Helper method to get age range string
  String get ageRange {
    if (minAge == maxAge) {
      return '$minAge years';
    }
    return '$minAge-$maxAge years';
  }
}
