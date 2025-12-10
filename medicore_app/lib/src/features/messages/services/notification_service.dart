import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';

/// Notification service for message alerts - uses system commands for reliability
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;
  bool _isPlaying = false;
  Timer? _loopTimer;
  String? _cachedSoundPath;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    print('🔊 NotificationService: Initializing...');
    
    try {
      // Always prepare the sound file
      await _prepareSoundFile();
      _isInitialized = true;
      print('✅ NotificationService initialized successfully');
    } catch (e) {
      print('❌ NotificationService: Failed to initialize - $e');
      _isInitialized = true; // Mark as initialized to prevent repeated failures
    }
  }
  
  /// Prepare sound file by copying asset to temp directory
  Future<void> _prepareSoundFile() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final soundFile = File('${tempDir.path}/medicore_notification.mp3');
      
      // Always re-copy to ensure file is fresh
      print('📁 Loading sound asset...');
      final data = await rootBundle.load('assets/sounds/notification.mp3');
      final bytes = data.buffer.asUint8List();
      print('📁 Sound asset loaded: ${bytes.length} bytes');
      
      await soundFile.writeAsBytes(bytes);
      _cachedSoundPath = soundFile.path;
      print('✅ Sound file ready at: $_cachedSoundPath');
      
      // Verify the file exists
      if (await soundFile.exists()) {
        final size = await soundFile.length();
        print('✅ Sound file verified: $size bytes');
      } else {
        print('❌ Sound file does not exist after write!');
      }
    } catch (e, stack) {
      print('❌ Failed to prepare sound file: $e');
      print('Stack: $stack');
    }
  }

  /// Play notification sound (loops until stopped)
  Future<void> playNotificationSound() async {
    print('🔊 NotificationService.playNotificationSound() called');
    
    // Initialize if needed
    if (!_isInitialized) {
      print('🔊 Not initialized, initializing now...');
      await initialize();
    }

    // Don't restart if already playing
    if (_isPlaying) {
      print('🔊 Sound already playing, skipping');
      return;
    }

    _isPlaying = true;
    print('🔊 Starting sound loop...');

    // Play first sound IMMEDIATELY
    await _playSoundOnce();
    
    // Cancel any existing timer
    _loopTimer?.cancel();
    
    // Then loop every 2 seconds
    _loopTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_isPlaying) {
        await _playSoundOnce();
      } else {
        timer.cancel();
      }
    });
  }
  
  /// Play sound once using the best available method
  Future<void> _playSoundOnce() async {
    print('🔊 _playSoundOnce() - cached path: $_cachedSoundPath');
    
    // Method 1: afplay on macOS with our cached file
    if (Platform.isMacOS && _cachedSoundPath != null) {
      final file = File(_cachedSoundPath!);
      if (await file.exists()) {
        try {
          print('🔊 Trying afplay with: $_cachedSoundPath');
          final result = await Process.run('afplay', [_cachedSoundPath!]);
          if (result.exitCode == 0) {
            print('✅ Sound played via afplay');
            return;
          } else {
            print('⚠️ afplay exit code: ${result.exitCode}, stderr: ${result.stderr}');
          }
        } catch (e) {
          print('⚠️ afplay exception: $e');
        }
      } else {
        print('⚠️ Cached sound file does not exist');
      }
    }
    
    // Method 2: macOS system sound as fallback
    if (Platform.isMacOS) {
      try {
        print('🔊 Trying macOS system sound fallback...');
        final result = await Process.run('afplay', ['/System/Library/Sounds/Glass.aiff']);
        if (result.exitCode == 0) {
          print('✅ Sound played via macOS system sound');
          return;
        }
      } catch (e) {
        print('⚠️ macOS system sound failed: $e');
      }
    }
    
    // Method 3: Windows PowerShell
    if (Platform.isWindows) {
      try {
        print('🔊 Trying Windows SystemSounds...');
        final result = await Process.run('powershell.exe', [
          '-NoProfile',
          '-WindowStyle', 'Hidden',
          '-Command',
          '[System.Media.SystemSounds]::Exclamation.Play()'
        ]);
        if (result.exitCode == 0) {
          print('✅ Sound played via Windows SystemSounds');
          return;
        }
      } catch (e) {
        print('⚠️ Windows SystemSounds failed: $e');
      }
      
      // Windows fallback: rundll32
      try {
        print('🔊 Trying Windows rundll32...');
        await Process.run('rundll32.exe', ['user32.dll,MessageBeep']);
        print('✅ Sound played via rundll32');
        return;
      } catch (e) {
        print('⚠️ rundll32 failed: $e');
      }
    }
    
    print('❌ All sound methods failed!');
  }

  /// Stop notification sound
  Future<void> stopNotificationSound() async {
    print('🔇 NotificationService: Stopping notification sound');
    _isPlaying = false;
    _loopTimer?.cancel();
    _loopTimer = null;
    print('✅ Sound stopped');
  }

  /// Dispose resources
  void dispose() {
    _loopTimer?.cancel();
    _loopTimer = null;
    _isPlaying = false;
  }
}
