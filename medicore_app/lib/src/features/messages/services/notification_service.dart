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

    // Always use macOS system sound for reliability
    if (Platform.isMacOS) {
      debugPrint('🔔 Using macOS system sound with loop');
      _startMacOSLoop();
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
    _loopTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_isPlaying) {
        try {
          await Process.run('afplay', ['/System/Library/Sounds/Glass.aiff']);
        } catch (e) {
          debugPrint('❌ Loop sound failed: $e');
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
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
