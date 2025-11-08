import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../services/profile_service.dart';
import '../services/profile_storage_service.dart';
import '../services/profile_validation_service.dart';
import '../services/avatar_upload_service.dart';
import '../../../shared/models/child_profile.dart';
import '../../../shared/widgets/themed_background.dart';
import '../../../shared/widgets/primary_cta_button.dart';

class ManageKidsPage extends StatefulWidget {
  const ManageKidsPage({super.key});

  @override
  State<ManageKidsPage> createState() => _ManageKidsPageState();
}

class _ManageKidsPageState extends State<ManageKidsPage> {
  List<ChildProfile> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      // Try to sync profiles from cloud first, fallback to local
      final profiles = await ProfileStorageService.syncProfiles();
      setState(() {
        _profiles = profiles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profiles: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Manage Kids'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/parental-dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: () => context.go('/parental-dashboard'),
          ),
        ],
      ),
      body: ThemedBackground(
        assetPath: 'assets/images/backgrounds/bg_dark.png',
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _profiles.isEmpty
                  ? _buildEmptyState()
                  : _buildProfilesList(),
        ),
      ),
      bottomNavigationBar: PrimaryCtaButton(
        label: 'Add New Child Profile   +',
        onPressed: () => _showAddProfileDialog(),
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.child_care,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No child profiles yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first child to get started with personalized stories',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showAddProfileDialog(),
              child: const Text('ADD CHILD'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilesList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _profiles.length,
      itemBuilder: (context, index) {
        final profile = _profiles[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF121A2A).withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF8AD3FF), width: 2),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFE3F4FF),
              backgroundImage: profile.avatarUrl != null
                  ? (profile.avatarUrl!.startsWith('http')
                      ? NetworkImage(profile.avatarUrl!)
                      : FileImage(File(profile.avatarUrl!)) as ImageProvider)
                  : null,
              child: profile.avatarUrl == null
                  ? Text(profile.childName[0].toUpperCase())
                  : null,
            ),
            title: Text(
              'Child Profile:',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                profile.childName,
                style: Theme.of(context).textTheme.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing: PopupMenuButton(
              color: const Color(0xFF1F2A44),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit Profile'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditProfileDialog(profile);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(profile);
                }
              },
            ),
            onTap: () {
              context.go('/home', extra: profile);
            },
          ),
        );
      },
    );
  }

  void _showAddProfileDialog() {
    final nameController = TextEditingController();
    final nicknameController = TextEditingController();
    int selectedAge = 5;
    File? selectedAvatar;
    String? nameError;
    String? nicknameError;
    String? ageError;
    String? profileCountError;
    bool isUploading = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Child Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar selection
                GestureDetector(
                  onTap: () async {
                    if (isUploading) return;
                    
                    setState(() { isUploading = true; });
                    print('Opening avatar selection dialog...');
                    final file = await AvatarUploadService.showImageSourceDialog(context);
                    print('Avatar selection result: $file');
                    setState(() { 
                      selectedAvatar = file;
                      isUploading = false;
                    });
                    print('Avatar updated: ${selectedAvatar != null ? selectedAvatar!.path : 'null'}');
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: selectedAvatar != null
                        ? ClipOval(
                            child: Image.file(
                              selectedAvatar!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.add_a_photo,
                            color: Colors.grey[600],
                            size: 32,
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Name field
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Child\'s Name',
                    hintText: 'Enter child\'s name',
                    errorText: nameError,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      nameError = ProfileValidationService.validateName(value);
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Nickname field
                TextField(
                  controller: nicknameController,
                  decoration: InputDecoration(
                    labelText: 'Nickname (Optional)',
                    hintText: 'Enter nickname',
                    errorText: nicknameError,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      nicknameError = ProfileValidationService.validateNickname(value);
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Age field
                DropdownButtonFormField<int>(
                  value: selectedAge,
                  decoration: InputDecoration(
                    labelText: 'Age',
                    errorText: ageError,
                    border: const OutlineInputBorder(),
                  ),
                  items: List.generate(12, (index) => index + 3)
                      .map((age) => DropdownMenuItem(
                            value: age,
                            child: Text('$age years old'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedAge = value ?? 5;
                      ageError = ProfileValidationService.validateAge(value);
                    });
                  },
                ),
                
                // Profile count warning
                if (profileCountError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    profileCountError!,
                    style: TextStyle(
                      color: Colors.red[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: isUploading ? null : () async {
                // Validate profile
                final existingNames = _profiles.map((p) => p.childName).toList();
                final errors = ProfileValidationService.validateProfile(
                  name: nameController.text,
                  nickname: nicknameController.text,
                  age: selectedAge,
                  existingNames: existingNames,
                  avatarPath: selectedAvatar?.path,
                  currentProfileCount: _profiles.length,
                );
                
                setState(() {
                  nameError = errors['name'];
                  nicknameError = errors['nickname'];
                  ageError = errors['age'];
                  profileCountError = errors['profileCount'];
                });
                
                if (ProfileValidationService.isProfileValid(errors)) {
                  await _addChildProfile(
                    nameController.text,
                    nicknameController.text.isEmpty ? null : nicknameController.text,
                    selectedAge,
                    selectedAvatar,
                  );
                  Navigator.pop(context);
                }
              },
              child: isUploading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addChildProfile(String name, String? nickname, int age, File? avatar) async {
    try {
      print('Adding child profile: $name, age: $age, avatar: ${avatar?.path}');
      final profileId = DateTime.now().millisecondsSinceEpoch.toString();
      String? avatarUrl;
      
      // Upload avatar if provided
      if (avatar != null) {
        print('Saving avatar locally...');
        // Save locally first
        final localPath = await AvatarUploadService.saveAvatarLocally(avatar, profileId);
        print('Local avatar path: $localPath');
        
        // Try to upload to cloud
        print('Uploading avatar to cloud...');
        avatarUrl = await AvatarUploadService.uploadAvatar(profileId, avatar);
        print('Cloud avatar URL: $avatarUrl');
        
        // If cloud upload fails, use local path
        if (avatarUrl == null && localPath != null) {
          avatarUrl = localPath;
          print('Using local avatar path: $avatarUrl');
        }
      }
      
      final newProfile = ChildProfile(
        id: profileId,
        userId: '', // Will be set by Supabase
        childName: ProfileValidationService.sanitizeName(name),
        nickname: nickname != null ? ProfileValidationService.sanitizeNickname(nickname) : null,
        ageBucket: age,
        avatarUrl: avatarUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      print('Created profile: ${newProfile.toJson()}');
      
      // Save to cloud first, then local
      print('Saving profile to cloud...');
      final cloudProfile = await ProfileStorageService.addCloudProfile(newProfile);
      if (cloudProfile != null) {
        print('Cloud profile saved: ${cloudProfile.toJson()}');
        await ProfileStorageService.addLocalProfile(cloudProfile);
        setState(() {
          _profiles.add(cloudProfile);
        });
        print('Profile added to UI list');
      } else {
        print('Cloud save failed, saving locally...');
        // Fallback to local only
        await ProfileStorageService.addLocalProfile(newProfile);
        setState(() {
          _profiles.add(newProfile);
        });
        print('Profile added to UI list (local only)');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${name}\'s profile added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditProfileDialog(ChildProfile profile) {
    final nameController = TextEditingController(text: profile.childName);
    final nicknameController = TextEditingController(text: profile.nickname ?? '');
    int selectedAge = profile.ageBucket;
    File? selectedAvatar;
    String? nameError;
    String? nicknameError;
    String? ageError;
    bool isUploading = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar selection
                GestureDetector(
                  onTap: () async {
                    if (isUploading) return;
                    
                    setState(() { isUploading = true; });
                    print('Opening avatar selection dialog (edit)...');
                    final file = await AvatarUploadService.showImageSourceDialog(context);
                    print('Avatar selection result (edit): $file');
                    setState(() { 
                      selectedAvatar = file;
                      isUploading = false;
                    });
                    print('Avatar updated (edit): ${selectedAvatar != null ? selectedAvatar!.path : 'null'}');
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: selectedAvatar != null
                        ? ClipOval(
                            child: Image.file(
                              selectedAvatar!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : profile.avatarUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  profile.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      color: Colors.grey[600],
                                      size: 32,
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.add_a_photo,
                                color: Colors.grey[600],
                                size: 32,
                              ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Name field
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Child\'s Name',
                    hintText: 'Enter child\'s name',
                    errorText: nameError,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      nameError = ProfileValidationService.validateName(value);
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Nickname field
                TextField(
                  controller: nicknameController,
                  decoration: InputDecoration(
                    labelText: 'Nickname (Optional)',
                    hintText: 'Enter nickname',
                    errorText: nicknameError,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      nicknameError = ProfileValidationService.validateNickname(value);
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Age field
                DropdownButtonFormField<int>(
                  value: selectedAge,
                  decoration: InputDecoration(
                    labelText: 'Age',
                    errorText: ageError,
                    border: const OutlineInputBorder(),
                  ),
                  items: List.generate(12, (index) => index + 3)
                      .map((age) => DropdownMenuItem(
                            value: age,
                            child: Text('$age years old'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedAge = value ?? 5;
                      ageError = ProfileValidationService.validateAge(value);
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: isUploading ? null : () async {
                // Validate profile
                final existingNames = _profiles
                    .where((p) => p.id != profile.id)
                    .map((p) => p.childName)
                    .toList();
                final errors = ProfileValidationService.validateProfile(
                  name: nameController.text,
                  nickname: nicknameController.text,
                  age: selectedAge,
                  existingNames: existingNames,
                  currentName: profile.childName,
                  avatarPath: selectedAvatar?.path,
                );
                
                setState(() {
                  nameError = errors['name'];
                  nicknameError = errors['nickname'];
                  ageError = errors['age'];
                });
                
                if (ProfileValidationService.isProfileValid(errors)) {
                  await _editChildProfile(
                    profile,
                    nameController.text,
                    nicknameController.text.isEmpty ? null : nicknameController.text,
                    selectedAge,
                    selectedAvatar,
                  );
                  Navigator.pop(context);
                }
              },
              child: isUploading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editChildProfile(ChildProfile profile, String name, String? nickname, int age, File? avatar) async {
    try {
      String? avatarUrl = profile.avatarUrl;
      
      // Handle avatar update
      if (avatar != null) {
        // Delete old avatar if exists
        if (profile.avatarUrl != null) {
          await AvatarUploadService.deleteAvatar(profile.id);
          await AvatarUploadService.deleteLocalAvatar(profile.id);
        }
        
        // Save new avatar locally first
        final localPath = await AvatarUploadService.saveAvatarLocally(avatar, profile.id);
        
        // Try to upload to cloud
        avatarUrl = await AvatarUploadService.uploadAvatar(profile.id, avatar);
        
        // If cloud upload fails, use local path
        if (avatarUrl == null && localPath != null) {
          avatarUrl = localPath;
        }
      }
      
      final updatedProfile = ChildProfile(
        id: profile.id,
        userId: profile.userId,
        childName: ProfileValidationService.sanitizeName(name),
        nickname: nickname != null ? ProfileValidationService.sanitizeNickname(nickname) : null,
        ageBucket: age,
        avatarUrl: avatarUrl,
        createdAt: profile.createdAt,
        updatedAt: DateTime.now(),
      );
      
      // Update in cloud first, then local
      final cloudProfile = await ProfileStorageService.updateCloudProfile(updatedProfile);
      if (cloudProfile != null) {
        await ProfileStorageService.updateLocalProfile(cloudProfile);
        setState(() {
          final index = _profiles.indexWhere((p) => p.id == profile.id);
          if (index != -1) {
            _profiles[index] = cloudProfile;
          }
        });
      } else {
        // Fallback to local only
        await ProfileStorageService.updateLocalProfile(updatedProfile);
        setState(() {
          final index = _profiles.indexWhere((p) => p.id == profile.id);
          if (index != -1) {
            _profiles[index] = updatedProfile;
          }
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${name}\'s profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(ChildProfile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text('Are you sure you want to delete ${profile.childName}\'s profile?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteChildProfile(profile);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChildProfile(ChildProfile profile) async {
    try {
      // Delete avatar if exists
      if (profile.avatarUrl != null) {
        await AvatarUploadService.deleteAvatar(profile.id);
        await AvatarUploadService.deleteLocalAvatar(profile.id);
      }
      
      // Delete from cloud first, then local
      final cloudDeleted = await ProfileStorageService.deleteCloudProfile(profile.id);
      await ProfileStorageService.deleteLocalProfile(profile.id);
      
      setState(() {
        _profiles.removeWhere((p) => p.id == profile.id);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${profile.childName}\'s profile deleted successfully!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
