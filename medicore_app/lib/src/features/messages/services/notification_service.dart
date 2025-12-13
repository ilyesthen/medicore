import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Notification service for message alerts - uses audioplayers for cross-platform support
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  AudioPlayer? _player;
  bool _isInitialized = false;
  bool _isPlaying = false;
  Timer? _loopTimer;
  String? _soundFilePath; // For Windows fallback

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    print('🔊 NotificationService: Initializing...');
    print('🔊 Platform: ${Platform.operatingSystem}');
    
    try {
      _player = AudioPlayer();
      
      // On Windows, copy asset to temp file for more reliable playback
      if (Platform.isWindows) {
        await _prepareWindowsSoundFile();
      }
      
      // Try to set source
      try {
        await _player!.setSource(AssetSource('sounds/notification.mp3'));
        await _player!.setReleaseMode(ReleaseMode.stop);
        print('✅ AudioPlayer source set successfully');
      } catch (e) {
        print('⚠️ Failed to set asset source: $e');
      }
      
      _isInitialized = true;
      print('✅ NotificationService initialized successfully');
    } catch (e) {
      print('❌ NotificationService: Failed to initialize - $e');
      _isInitialized = true; // Mark as initialized to prevent repeated failures
    }
  }
  
  /// Prepare sound file for Windows (copy from assets to temp)
  Future<void> _prepareWindowsSoundFile() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final soundFile = File('${tempDir.path}/medicore_notification.mp3');
      
      print('📁 Preparing Windows sound file...');
      final data = await rootBundle.load('assets/sounds/notification.mp3');
      await soundFile.writeAsBytes(data.buffer.asUint8List());
      _soundFilePath = soundFile.path;
      print('✅ Windows sound file ready: $_soundFilePath');
    } catch (e) {
      print('⚠️ Failed to prepare Windows sound file: $e');
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
    
    // Then loop every 3 seconds
    _loopTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isPlaying) {
        await _playSoundOnce();
      } else {
        timer.cancel();
      }
    });
  }
  
  /// Play sound once
  Future<void> _playSoundOnce() async {
    try {
      if (_player == null) {
        print('⚠️ Player is null, creating new player...');
        _player = AudioPlayer();
      }
      
      // Stop any current playback first
      await _player!.stop();
      
      // On Windows, try DeviceFileSource first (more reliable)
      if (Platform.isWindows && _soundFilePath != null) {
        try {
          await _player!.play(DeviceFileSource(_soundFilePath!));
          print('✅ Sound played via DeviceFileSource (Windows)');
          return;
        } catch (e) {
          print('⚠️ DeviceFileSource failed: $e, trying AssetSource...');
        }
      }
      
      // Play from asset (works on macOS, Linux, and as fallback on Windows)
      await _player!.play(AssetSource('sounds/notification.mp3'));
      print('✅ Sound played via AssetSource');
    } catch (e) {
      print('❌ Failed to play sound: $e');
    }
  }

  /// Stop notification sound
  Future<void> stopNotificationSound() async {
    print('🔇 NotificationService: Stopping notification sound');
    _isPlaying = false;
    _loopTimer?.cancel();
    _loopTimer = null;
    
    try {
      await _player?.stop();
    } catch (e) {
      print('⚠️ Failed to stop player: $e');
    }
    print('✅ Sound stopped');
  }

  /// Dispose resources
  void dispose() {
    _loopTimer?.cancel();
    _loopTimer = null;
    _isPlaying = false;
    _player?.dispose();
    _player = null;
  }
}
