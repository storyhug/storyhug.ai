import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Placeholder post-processing layer that ensures generated audio files live in
/// a predictable directory. The hook allows swapping in a real normalization
/// routine later (FFmpeg, native DSP, etc.).
class AudioPostProcessingService {
  static final AudioPostProcessingService _instance =
      AudioPostProcessingService._internal();
  factory AudioPostProcessingService() => _instance;
  AudioPostProcessingService._internal();

  Future<String> ensureDirectory(String folderName) async {
    final docs = await getApplicationDocumentsDirectory();
    final audioDir = Directory(p.join(docs.path, folderName));
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return audioDir.path;
  }

  Future<File> finalize(File file) async {
    if (await file.exists()) {
      await file.setLastModified(DateTime.now());
    }
    return file;
  }
}
