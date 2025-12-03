import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../config/storage_config.dart';

/// Handles all file system operations for audio recordings
/// 
/// This service manages:
/// - File path generation with user-controlled paths
/// - Directory creation and management
/// - File deletion and cleanup
/// - Access to recording files
class RecorderStorageHandler {
  /// Storage configuration
  StorageConfig? _config;

  /// Set storage configuration
  void setConfig(StorageConfig config) {
    _config = config;
  }

  /// Gets the recording path based on configuration
  /// 
  /// Priority:
  /// 1. User-provided path (exact path)
  /// 2. Custom directory + auto-generated filename
  /// 3. Temp directory + auto-generated filename (default)
  /// 
  /// [fileName] - Optional filename to use (overrides auto-generation)
  Future<String> getRecordingPath({String? fileName}) async {
    final config = _config;
    
    // Priority 1: User provided exact path
    final userPath = config?.userProvidedPath;
    if (userPath != null && userPath.isNotEmpty) {
      final directory = Directory(path.dirname(userPath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      print('RecorderStorageHandler: Using user-provided path - $userPath');
      return userPath;
    }
    
    // Priority 3: Temp directory (default fallback)
    if (config?.useTempDirectory ?? true) {
      final tempDir = await getTemporaryDirectory();
      final filename = fileName ?? _generateFilename(config);
      final filePath = path.join(tempDir.path, filename);
      
      print('RecorderStorageHandler: Using temp directory - $filePath');
      return filePath;
    }
    
    // Final fallback: App documents directory
    final appDir = await getApplicationDocumentsDirectory();
    final filename = fileName ?? _generateFilename(config);
    final filePath = path.join(appDir.path, filename);
    
    print('RecorderStorageHandler: Using app directory - $filePath');
    return filePath;
  }

  /// Generates filename based on configuration
  String _generateFilename(StorageConfig? config) {
    final prefix = config?.filenamePrefix ?? 'recording';
    final extension = config?.fileExtension ?? 'm4a';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    return '${prefix}_$timestamp.$extension';
  }

  /// Deletes a recording file from storage
  /// 
  /// [filePath] - Full path to the recording file to delete
  /// 
  /// Returns true if deletion was successful, false otherwise
  Future<bool> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      
      if (await file.exists()) {
        await file.delete();
        print('RecorderStorageHandler: Deleted - $filePath');
        return true;
      }
      
      print('RecorderStorageHandler: File not found - $filePath');
      return false;
    } catch (e) {
      print('RecorderStorageHandler: Delete error - $e');
      return false;
    }
  }
}
