import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Handles all file system operations for audio recordings
/// 
/// This service manages:
/// - File path generation with unique timestamps
/// - Directory creation and management
/// - File deletion and cleanup
/// - Access to recording files
class RecorderStorageHandler {
  /// Directory name for storing recordings
  static const String _recordingsDir = 'recordings';

  /// Generates a unique file path for a new recording in hidden storage
  /// 
  /// Hidden storage is used for temporary recordings that haven't been
  /// finalized yet. Files here won't appear in user's file manager.
  /// 
  /// [fileName] - Name of the recording file (e.g., 'recording_123456.m4a')
  /// 
  /// Returns the full path where the recording should be saved
  /// 
  /// Example: '/data/user/0/com.example.app/app_flutter/recordings/recording_123456.m4a'
  Future<String> getHiddenRecordingPath(String fileName) async {
    try {
      // Get app's private directory
      final directory = await getApplicationDocumentsDirectory();
      
      // Create recordings subdirectory if it doesn't exist
      final recordingsPath = '${directory.path}/$_recordingsDir';
      final recordingsDir = Directory(recordingsPath);
      
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }
      
      return '$recordingsPath/$fileName';
    } catch (e) {
      throw Exception('Failed to get recording path: $e');
    }
  }

  /// Generates a file path in public storage (user-accessible)
  /// 
  /// Public storage allows users to access recordings through file manager.
  /// Use this for finalized recordings that should be visible to users.
  /// 
  /// [fileName] - Name of the recording file
  /// 
  /// Returns the full path in public storage
  Future<String> getPublicRecordingPath(String fileName) async {
    try {
      Directory? directory;
      
      if (Platform.isAndroid) {
        // Use external storage on Android
        directory = await getExternalStorageDirectory();
      } else {
        // Use documents directory on iOS
        directory = await getApplicationDocumentsDirectory();
      }
      
      if (directory == null) {
        throw Exception('Could not access storage directory');
      }
      
      final recordingsPath = '${directory.path}/$_recordingsDir';
      final recordingsDir = Directory(recordingsPath);
      
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }
      
      return '$recordingsPath/$fileName';
    } catch (e) {
      throw Exception('Failed to get public recording path: $e');
    }
  }

  /// Gets a File object for an existing recording
  /// 
  /// [path] - Full path to the recording file
  /// 
  /// Returns a File object if the file exists, null otherwise
  Future<File?> getRecordingFile(String path) async {
    try {
      final file = File(path);
      
      if (await file.exists()) {
        return file;
      }
      
      return null;
    } catch (e) {
      print('Error getting recording file: $e');
      return null;
    }
  }

  /// Deletes a recording file from storage
  /// 
  /// [path] - Full path to the recording file to delete
  /// 
  /// Returns true if deletion was successful, false otherwise
  Future<bool> deleteRecording(String path) async {
    try {
      final file = File(path);
      
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error deleting recording: $e');
      return false;
    }
  }

  /// Gets the recordings directory
  /// 
  /// Returns the Directory object for the recordings folder
  Future<Directory> getRecordingsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final recordingsPath = '${directory.path}/$_recordingsDir';
    return Directory(recordingsPath);
  }
}
