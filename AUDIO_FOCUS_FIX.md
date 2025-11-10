# Audio Focus Fix - Recording Pause on Background Apps

## Problem
When starting recording and going to background mode, then opening YouTube (or any other media app) and playing a video, the recording was NOT pausing. This is a critical issue because:

1. The recording continues even when other apps are playing audio
2. This can cause audio conflicts and poor user experience
3. Users expect recording to pause when other apps take audio focus

## Root Cause
The app was missing **audio focus change detection** for Android. While the app had:
- ✅ System interruption handling (phone calls)
- ✅ Device change handling (headphones disconnect)
- ✅ Becoming noisy event handling

It was **missing**:
- ❌ Audio focus change listener (when other apps like YouTube request audio focus)

### Technical Details
When YouTube (or any media app) starts playing:
1. YouTube requests audio focus from the Android system
2. Android grants focus to YouTube and removes it from your recording app
3. Your app should detect this focus loss and pause recording
4. **BUT** - your app wasn't listening to the `androidAudioFocusStream`, so it never knew it lost focus

## Solution
Added audio focus change detection to `audio_session_service.dart`:

### Changes Made

1. **Added audio focus subscription**:
```dart
StreamSubscription<bool>? _audioFocusSubscription;
```

2. **Set up audio focus listener** in `_setupInterruptionStreams()`:
```dart
// 4. Audio focus changes (when other apps request audio focus)
_audioFocusSubscription = session
    .androidAudioFocusStream
    .listen(_handleAudioFocusChange);
```

3. **Implemented audio focus change handler**:
```dart
/// Handles audio focus changes (Android only)
/// 
/// This detects when other apps (like YouTube, Spotify, etc.) request audio focus
/// and our app loses it. When focus is lost, we should pause recording.
void _handleAudioFocusChange(bool hasFocus) {
  print('AudioSessionService: Audio focus changed - hasFocus: $hasFocus');
  
  if (!hasFocus) {
    // Lost audio focus to another app (e.g., YouTube, Spotify)
    print('AudioSessionService: Lost audio focus - pausing recording');
    _emitInterruption(
      InterruptionType.mediaPlayback,
      shouldPause: true,
    );
  } else {
    // Regained audio focus
    print('AudioSessionService: Regained audio focus');
  }
}
```

4. **Added cleanup** in `dispose()`:
```dart
_audioFocusSubscription?.cancel();
```

## How It Works Now

### Scenario: Recording → Background → YouTube
1. User starts recording ✅
2. User presses home button (app goes to background) ✅
3. User opens YouTube ✅
4. User plays a video ✅
5. **YouTube requests audio focus** 🎯
6. **Your app detects focus loss** 🎯
7. **Recording automatically pauses** ✅
8. User sees "Recording paused: mediaPlayback" message ✅

### What Gets Detected
The app now detects and auto-pauses recording for:
- ✅ Phone calls (system interruption)
- ✅ Headphone disconnect (device change)
- ✅ Bluetooth disconnect (device change)
- ✅ Becoming noisy events
- ✅ **Other media apps playing (YouTube, Spotify, etc.)** ← NEW!

## Testing
To test the fix:

1. Start recording in your app
2. Press home button to go to background
3. Open YouTube
4. Play any video
5. **Expected**: Recording should automatically pause
6. Check logs for: `AudioSessionService: Lost audio focus - pausing recording`

## Platform Support
- **Android**: ✅ Fully supported via `androidAudioFocusStream`
- **iOS**: ✅ Already handled via system interruptions (iOS has different audio session management)

## Additional Notes
- The audio focus listener is Android-specific but safe to use on iOS (it just won't emit events)
- The `androidWillPauseWhenDucked: true` setting ensures recording pauses when audio is "ducked" (volume lowered)
- The fix integrates seamlessly with existing interruption handling via the `InterruptionType.mediaPlayback` enum

## Files Modified
- `lib/services/recording_services/audio_session_service.dart`

## Related Documentation
- See `INTERRUPTION_FIX.md` for general interruption handling
- See `README_DEVELOPER.md` for architecture overview
