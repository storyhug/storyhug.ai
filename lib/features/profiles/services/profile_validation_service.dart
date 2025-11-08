class ProfileValidationService {
  // Validation rules
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int minNicknameLength = 2;
  static const int maxNicknameLength = 30;
  static const int minAge = 3;
  static const int maxAge = 14;
  static const int maxProfilesPerUser = 5;

  // Name validation
  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Child\'s name is required';
    }

    final trimmedName = name.trim();
    
    if (trimmedName.length < minNameLength) {
      return 'Name must be at least $minNameLength characters long';
    }

    if (trimmedName.length > maxNameLength) {
      return 'Name must be less than $maxNameLength characters';
    }

    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(trimmedName)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }

    // Check for consecutive spaces
    if (trimmedName.contains('  ')) {
      return 'Name cannot contain consecutive spaces';
    }

    // Check for leading/trailing spaces (shouldn't happen after trim, but just in case)
    if (name != trimmedName) {
      return 'Name cannot start or end with spaces';
    }

    return null;
  }

  // Nickname validation
  static String? validateNickname(String? nickname) {
    if (nickname == null || nickname.trim().isEmpty) {
      return null; // Nickname is optional
    }

    final trimmedNickname = nickname.trim();
    
    if (trimmedNickname.length < minNicknameLength) {
      return 'Nickname must be at least $minNicknameLength characters long';
    }

    if (trimmedNickname.length > maxNicknameLength) {
      return 'Nickname must be less than $maxNicknameLength characters';
    }

    // Check for valid characters (letters, numbers, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z0-9\s\-']+$").hasMatch(trimmedNickname)) {
      return 'Nickname can only contain letters, numbers, spaces, hyphens, and apostrophes';
    }

    // Check for consecutive spaces
    if (trimmedNickname.contains('  ')) {
      return 'Nickname cannot contain consecutive spaces';
    }

    return null;
  }

  // Age validation
  static String? validateAge(int? age) {
    if (age == null) {
      return 'Age is required';
    }

    if (age < minAge) {
      return 'Child must be at least $minAge years old';
    }

    if (age > maxAge) {
      return 'Child must be less than $maxAge years old';
    }

    return null;
  }

  // Profile count validation
  static String? validateProfileCount(int currentCount) {
    if (currentCount >= maxProfilesPerUser) {
      return 'You can only create up to $maxProfilesPerUser child profiles';
    }

    return null;
  }

  // Duplicate name validation
  static String? validateDuplicateName(String name, List<String> existingNames, String? currentName) {
    final trimmedName = name.trim().toLowerCase();
    
    // Don't check against the current name being edited
    if (currentName != null && currentName.toLowerCase() == trimmedName) {
      return null;
    }

    final existingNamesLower = existingNames.map((n) => n.toLowerCase()).toList();
    
    if (existingNamesLower.contains(trimmedName)) {
      return 'A child with this name already exists';
    }

    return null;
  }

  // Avatar validation
  static String? validateAvatar(String? filePath) {
    if (filePath == null || filePath.isEmpty) {
      return null; // Avatar is optional
    }

    // Check file extension
    final extension = filePath.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
      return 'Avatar must be a JPG, PNG, or WebP image';
    }

    return null;
  }

  // Comprehensive validation
  static Map<String, String?> validateProfile({
    required String? name,
    required String? nickname,
    required int? age,
    required List<String> existingNames,
    String? currentName,
    String? avatarPath,
    int? currentProfileCount,
  }) {
    final errors = <String, String?>{};

    // Validate name
    errors['name'] = validateName(name);

    // Validate nickname
    errors['nickname'] = validateNickname(nickname);

    // Validate age
    errors['age'] = validateAge(age);

    // Validate duplicate name
    if (name != null && name.isNotEmpty) {
      errors['duplicateName'] = validateDuplicateName(name, existingNames, currentName);
    }

    // Validate avatar
    errors['avatar'] = validateAvatar(avatarPath);

    // Validate profile count (only when adding new profile)
    if (currentName == null && currentProfileCount != null) {
      errors['profileCount'] = validateProfileCount(currentProfileCount);
    }

    return errors;
  }

  // Check if profile is valid
  static bool isProfileValid(Map<String, String?> errors) {
    return errors.values.every((error) => error == null);
  }

  // Get first error message
  static String? getFirstError(Map<String, String?> errors) {
    for (final error in errors.values) {
      if (error != null) {
        return error;
      }
    }
    return null;
  }

  // Get all error messages
  static List<String> getAllErrors(Map<String, String?> errors) {
    return errors.values.where((error) => error != null).cast<String>().toList();
  }

  // Sanitize input
  static String sanitizeName(String name) {
    return name.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String sanitizeNickname(String nickname) {
    return nickname.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // Age group categorization
  static String getAgeGroup(int age) {
    if (age >= 3 && age <= 5) {
      return 'Preschool';
    } else if (age >= 6 && age <= 8) {
      return 'Early Elementary';
    } else if (age >= 9 && age <= 11) {
      return 'Late Elementary';
    } else if (age >= 12 && age <= 14) {
      return 'Middle School';
    } else {
      return 'Unknown';
    }
  }

  // Content recommendations based on age
  static List<String> getRecommendedCategories(int age) {
    if (age >= 3 && age <= 5) {
      return ['Fairy Tales', 'Animal Stories', 'Simple Adventures'];
    } else if (age >= 6 && age <= 8) {
      return ['Moral Stories', 'Adventure', 'Indian Mythology'];
    } else if (age >= 9 && age <= 11) {
      return ['Indian Mythology', 'Adventure', 'Moral Stories', 'Historical Tales'];
    } else if (age >= 12 && age <= 14) {
      return ['Indian Mythology', 'Historical Tales', 'Adventure', 'Moral Stories'];
    } else {
      return ['Moral Stories', 'Adventure'];
    }
  }
}
