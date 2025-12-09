import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';

/// Enterprise-grade notification service for message alerts
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;
  bool _isPlaying = false;
  Timer? _loopTimer;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Set to loop mode
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      _isInitialized = true;
      debugPrint('✅ NotificationService initialized');
    } catch (e) {
      debugPrint('❌ NotificationService: Failed to initialize - $e');
    }
  }

  /// Play notification sound (loops until stopped)
  Future<void> playNotificationSound() async {
    debugPrint('🔊 NotificationService: Playing notification sound...');
    
    if (!_isInitialized) {
      await initialize();
    }

    // Don't restart if already playing
    if (_isPlaying) {
      debugPrint('🔊 Sound already playing, skipping');
      return;
    }

    _isPlaying = true;

    // Platform-specific sound playback for reliability
    if (Platform.isMacOS) {
      debugPrint('🔔 Using macOS system sound with loop');
      _startMacOSLoop();
      return;
    }

    if (Platform.isWindows) {
      debugPrint('🔔 Using Windows system sound with loop');
      _startWindowsLoop();
      return;
    }

    // Fallback to asset for other platforms
    try {
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
      debugPrint('✅ Sound playing (will loop until stopped)');
    } catch (e) {
      debugPrint('⚠️  AudioPlayer failed: $e');
      _isPlaying = false;
    }
  }

  /// Start macOS system sound loop
  void _startMacOSLoop() {
    _loopTimer?.cancel();
    
    // Play first sound IMMEDIATELY
    _playMacOSSound();
    
    // Then loop every 2 seconds
    _loopTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_isPlaying) {
        _playMacOSSound();
      } else {
        timer.cancel();
      }
    });
  }
  
  /// Play macOS sound - try multiple methods for reliability
  Future<void> _playMacOSSound() async {
    try {
      // Method 1: Try afplay (system command)
      await Process.run('afplay', ['/System/Library/Sounds/Glass.aiff']);
      debugPrint('🔊 macOS sound played via afplay');
    } catch (e) {
      debugPrint('⚠️ afplay failed: $e, trying AudioPlayer...');
      // Method 2: Fallback to audioplayer with asset
      try {
        await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
        debugPrint('🔊 Sound played via AudioPlayer');
      } catch (e2) {
        debugPrint('❌ All sound methods failed: $e2');
      }
    }
  }

  /// Start Windows system sound loop
  void _startWindowsLoop() {
    _loopTimer?.cancel();
    
    // Play first sound IMMEDIATELY
    _playWindowsSound();
    
    // Then loop every 2 seconds
    _loopTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_isPlaying) {
        _playWindowsSound();
      } else {
        timer.cancel();
      }
    });
  }

  /// Play Windows sound - use rundll32 for system beep or AudioPlayer
  Future<void> _playWindowsSound() async {
    try {
      // Method 1: Try rundll32 for system sound (more reliable than PowerShell)
      final result = await Process.run('rundll32', [
        'user32.dll,MessageBeep',
      ]);
      if (result.exitCode == 0) {
        debugPrint('🔊 Windows sound played via rundll32');
        return;
      }
    } catch (e) {
      debugPrint('⚠️ rundll32 failed: $e');
    }

    // Method 2: Try PowerShell as backup
    try {
      await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        '[Console]::Beep(800, 200); [Console]::Beep(1000, 200)'
      ]);
      debugPrint('🔊 Windows sound played via PowerShell Beep');
      return;
    } catch (e) {
      debugPrint('⚠️ PowerShell beep failed: $e');
    }

    // Method 3: Fallback to audioplayer with asset
    try {
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
      debugPrint('🔊 Sound played via AudioPlayer');
    } catch (e2) {
      debugPrint('❌ All sound methods failed: $e2');
    }
  }

  /// Stop notification sound
  Future<void> stopNotificationSound() async {
    debugPrint('🔇 NotificationService: Stopping notification sound');
    _isPlaying = false;
    _loopTimer?.cancel();
    
    try {
      await _audioPlayer.stop();
      debugPrint('✅ Sound stopped');
    } catch (e) {
      debugPrint('⚠️  Failed to stop sound: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _loopTimer?.cancel();
    _audioPlayer.dispose();
  }
}
