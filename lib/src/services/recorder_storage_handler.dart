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
      // Ensure directory exists
      final directory = Directory(path.dirname(userPath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      print('RecorderStorageHandler: Using user-provided path - $userPath');
      return userPath;
    }
    
    // Priority 2: Custom directory
    final customDir = config?.customDirectory;
    if (customDir != null && customDir.isNotEmpty) {
      final directory = Directory(customDir);
      
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      final filename = fileName ?? _generateFilename(config);
      final filePath = path.join(directory.path, filename);
      
      print('RecorderStorageHandler: Using custom directory - $filePath');
      return filePath;
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

  /// Validates that the path is writable
  Future<bool> validatePath(String filePath) async {
    try {
      final directory = Directory(path.dirname(filePath));
      
      // Check if directory exists or can be created
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // Try to create a test file
      final testFile = File('${filePath}_test');
      await testFile.writeAsString('test');
      await testFile.delete();
      
      return true;
    } catch (e) {
      print('RecorderStorageHandler: Path validation failed - $e');
      return false;
    }
  }

  /// Gets temp directory path
  Future<String> getTempDirectory() async {
    final tempDir = await getTemporaryDirectory();
    return tempDir.path;
  }

  /// Gets app documents directory path
  Future<String> getAppDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return appDir.path;
  }

  /// Gets a File object for an existing recording
  /// 
  /// [filePath] - Full path to the recording file
  /// 
  /// Returns a File object if the file exists, null otherwise
  Future<File?> getRecordingFile(String filePath) async {
    try {
      final file = File(filePath);
      
      if (await file.exists()) {
        return file;
      }
      
      return null;
    } catch (e) {
      print('RecorderStorageHandler: Error getting recording file - $e');
      return null;
    }
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

  /// Deletes metadata file associated with recording
  Future<bool> deleteMetadata(String recordingPath) async {
    try {
      final metadataPath = '$recordingPath.json';
      final file = File(metadataPath);
      
      if (await file.exists()) {
        await file.delete();
        print('RecorderStorageHandler: Deleted metadata - $metadataPath');
        return true;
      }
      
      return false;
    } catch (e) {
      print('RecorderStorageHandler: Delete metadata error - $e');
      return false;
    }
  }

  /// Gets the recordings directory
  /// 
  /// Returns the Directory object for the recordings folder
  Future<Directory> getRecordingsDirectory() async {
    final config = _config;
    
    // Use custom directory if provided
    final customDir = config?.customDirectory;
    if (customDir != null && customDir.isNotEmpty) {
      return Directory(customDir);
    }
    
    // Use temp directory if configured
    if (config?.useTempDirectory ?? true) {
      return await getTemporaryDirectory();
    }
    
    // Default to app documents
    return await getApplicationDocumentsDirectory();
  }

  /// Lists all recording files in the recordings directory
  /// 
  /// Returns a list of File objects for all recordings
  Future<List<File>> listRecordings() async {
    try {
      final directory = await getRecordingsDirectory();
      
      if (!await directory.exists()) {
        return [];
      }

      final entities = await directory.list().toList();
      final files = entities
          .whereType<File>()
          .where((file) => !file.path.endsWith('.json')) // Exclude metadata files
          .toList();
      
      return files;
    } catch (e) {
      print('RecorderStorageHandler: Error listing recordings - $e');
      return [];
    }
  }

  /// Gets file size in bytes
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.size;
      }
      return 0;
    } catch (e) {
      print('RecorderStorageHandler: Error getting file size - $e');
      return 0;
    }
  }

  /// Checks if file exists
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      print('RecorderStorageHandler: Error checking file existence - $e');
      return false;
    }
  }
}
