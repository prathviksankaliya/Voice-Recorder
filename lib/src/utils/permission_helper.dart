import 'package:permission_handler/permission_handler.dart';

/// Helper class for managing app permissions
/// 
/// Handles requesting and checking permissions for:
/// - Microphone (required for recording)
/// - Storage (required for saving recordings on Android)
/// - Notifications (required for background service on Android)
class PermissionHelper {
  /// Requests all required permissions for recording
  /// 
  /// Returns true if all permissions are granted.
  static Future<bool> requestRecordingPermissions() async {
    try {
      // Request microphone permission
      final micStatus = await Permission.microphone.request();
      
      if (micStatus.isDenied || micStatus.isPermanentlyDenied) {
        print('PermissionHelper: Microphone permission denied');
        return false;
      }

      print('PermissionHelper: All permissions granted');
      return true;
    } catch (e) {
      print('PermissionHelper: Error requesting permissions - $e');
      return false;
    }
  }

  /// Checks if all required permissions are granted
  /// 
  /// Returns true if all permissions are granted.
  static Future<bool> checkRecordingPermissions() async {
    try {
      // Check microphone permission
      final micStatus = await Permission.microphone.status;
      
      if (!micStatus.isGranted) {
        print('PermissionHelper: Microphone permission not granted');
        return false;
      }

      return true;
    } catch (e) {
      print('PermissionHelper: Error checking permissions - $e');
      return false;
    }
  }

  /// Checks if microphone permission is granted
  static Future<bool> hasMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      return status.isGranted;
    } catch (e) {
      print('PermissionHelper: Error checking microphone permission - $e');
      return false;
    }
  }

  /// Opens app settings for manual permission management
  static Future<void> openSettings() async {
    try {
      await openAppSettings();
      print('PermissionHelper: Opened app settings');
    } catch (e) {
      print('PermissionHelper: Error opening app settings - $e');
    }
  }

  /// Checks if a permission is permanently denied
  /// 
  /// Returns true if the user has permanently denied the permission.
  static Future<bool> isPermissionPermanentlyDenied(Permission permission) async {
    try {
      final status = await permission.status;
      return status.isPermanentlyDenied;
    } catch (e) {
      print('PermissionHelper: Error checking permanent denial - $e');
      return false;
    }
  }
}
