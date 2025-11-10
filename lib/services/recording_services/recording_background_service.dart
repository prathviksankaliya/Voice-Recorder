import 'dart:io';
import 'package:flutter_background/flutter_background.dart';

/// Manages background execution for audio recording
/// 
/// This singleton service ensures recording continues when the app is in background:
/// - **Android**: Uses foreground service with notification
/// - **iOS**: Uses native audio background mode (configured in Info.plist)
/// 
/// Use [RecordingBackgroundService.instance] to access the singleton.
class RecordingBackgroundService {
  /// Singleton instance
  static final RecordingBackgroundService instance = 
      RecordingBackgroundService._internal();
  
  /// Private constructor for singleton
  RecordingBackgroundService._internal();

  /// Whether the background service is currently running
  bool _isRunning = false;

  /// Whether the service has been initialized
  bool _isInitialized = false;

  /// Whether the background service is running
  bool get isRunning => _isRunning;

  /// Whether the service is initialized
  bool get isInitialized => _isInitialized;

  /// Initializes the background service
  /// 
  /// For Android, this configures the foreground service notification.
  /// For iOS, no initialization is needed (uses Info.plist configuration).
  /// 
  /// Returns true if initialization was successful.
  Future<bool> initialize() async {
    try {
      if (_isInitialized) {
        print('BackgroundService: Already initialized');
        return true;
      }

      // iOS doesn't need initialization - uses Info.plist background modes
      if (!Platform.isAndroid) {
        _isInitialized = true;
        print('BackgroundService: iOS - no initialization needed');
        return true;
      }

      // Android: Configure foreground service notification
      final androidConfig = FlutterBackgroundAndroidConfig(
        notificationTitle: 'Recording in Progress',
        notificationText: 'Your audio is being recorded',
        notificationImportance: AndroidNotificationImportance.normal,
        notificationIcon: AndroidResource(
          name: 'ic_launcher',
          defType: 'mipmap',
        ),
        enableWifiLock: true,
      );

      final success = await FlutterBackground.initialize(
        androidConfig: androidConfig,
      );

      _isInitialized = success;
      
      if (success) {
        print('BackgroundService: Android initialized successfully');
      } else {
        print('BackgroundService: Android initialization failed');
      }

      return success;
    } catch (e) {
      print('BackgroundService: Initialization error - $e');
      return false;
    }
  }

  /// Starts the background service
  /// 
  /// For Android, this starts the foreground service and shows notification.
  /// For iOS, this just marks the service as running (background audio is automatic).
  /// 
  /// Returns true if the service started successfully.
  Future<bool> startService() async {
    try {
      // Initialize if not already done
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          print('BackgroundService: Cannot start - initialization failed');
          return false;
        }
      }

      // iOS: Just mark as running (background audio is automatic)
      if (!Platform.isAndroid) {
        _isRunning = true;
        print('BackgroundService: iOS - marked as running');
        return true;
      }

      // Android: Check permissions
      final hasPermissions = await FlutterBackground.hasPermissions;
      if (!hasPermissions) {
        print('BackgroundService: Missing permissions');
        return false;
      }

      // Android: Enable background execution
      final success = await FlutterBackground.enableBackgroundExecution();
      _isRunning = success;

      if (success) {
        print('BackgroundService: Android service started');
      } else {
        print('BackgroundService: Android service failed to start');
      }

      return success;
    } catch (e) {
      print('BackgroundService: Start service error - $e');
      return false;
    }
  }

  /// Stops the background service
  /// 
  /// For Android, this stops the foreground service and removes notification.
  /// For iOS, this just marks the service as stopped.
  /// 
  /// Returns true if the service stopped successfully.
  Future<bool> stopService() async {
    try {
      if (!_isRunning) {
        print('BackgroundService: Service not running');
        return true;
      }

      // iOS: Just mark as stopped
      if (!Platform.isAndroid) {
        _isRunning = false;
        print('BackgroundService: iOS - marked as stopped');
        return true;
      }

      // Android: Disable background execution
      final success = await FlutterBackground.disableBackgroundExecution();
      _isRunning = false;

      if (success) {
        print('BackgroundService: Android service stopped');
      } else {
        print('BackgroundService: Android service stop failed');
      }

      return success;
    } catch (e) {
      print('BackgroundService: Stop service error - $e');
      _isRunning = false;
      return false;
    }
  }

  /// Checks if the service is currently running
  /// 
  /// Returns true if background service is active.
  Future<bool> checkIsRunning() async {
    return _isRunning;
  }
}
