import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Service to launch and manage the Go gRPC server
/// This server runs on the admin machine to serve data to clients
class GrpcServerLauncher {
  static Process? _serverProcess;
  static bool _isRunning = false;
  
  /// Start the gRPC server (admin only)
  static Future<bool> start() async {
    if (_isRunning) {
      print('✓ gRPC server already running');
      return true;
    }
    
    try {
      // Find the server executable
      final serverPath = await _findServerExecutable();
      if (serverPath == null) {
        print('❌ gRPC server executable not found');
        return false;
      }
      
      print('🚀 Starting gRPC server: $serverPath');
      
      // Start the server process
      _serverProcess = await Process.start(
        serverPath,
        [],
        mode: ProcessStartMode.detached,
      );
      
      // Listen to output
      _serverProcess!.stdout.listen((data) {
        print('[gRPC Server] ${String.fromCharCodes(data)}');
      });
      
      _serverProcess!.stderr.listen((data) {
        print('[gRPC Server ERROR] ${String.fromCharCodes(data)}');
      });
      
      _isRunning = true;
      print('✅ gRPC server started successfully on port 50051');
      return true;
      
    } catch (e) {
      print('❌ Failed to start gRPC server: $e');
      return false;
    }
  }
  
  /// Stop the gRPC server
  static Future<void> stop() async {
    if (_serverProcess != null) {
      _serverProcess!.kill();
      _serverProcess = null;
      _isRunning = false;
      print('✓ gRPC server stopped');
    }
  }
  
  /// Check if server is running
  static bool get isRunning => _isRunning;
  
  /// Find the gRPC server executable
  static Future<String?> _findServerExecutable() async {
    if (Platform.isWindows) {
      // Check in app directory
      final exePath = Platform.resolvedExecutable;
      final appDir = p.dirname(exePath);
      
      // Look for medicore_server.exe in same directory as Flutter app
      final serverInAppDir = p.join(appDir, 'medicore_server.exe');
      if (await File(serverInAppDir).exists()) {
        return serverInAppDir;
      }
      
      // Also try with hyphen for backwards compatibility
      final serverInAppDirAlt = p.join(appDir, 'medicore-server.exe');
      if (await File(serverInAppDirAlt).exists()) {
        return serverInAppDirAlt;
      }
      
      // Look in subdirectory
      final serverInBin = p.join(appDir, 'bin', 'medicore_server.exe');
      if (await File(serverInBin).exists()) {
        return serverInBin;
      }
      
      // Look in server subdirectory
      final serverInServer = p.join(appDir, 'server', 'medicore_server.exe');
      if (await File(serverInServer).exists()) {
        return serverInServer;
      }
      
      print('⚠️ Searched paths:');
      print('   - $serverInAppDir');
      print('   - $serverInAppDirAlt');
      print('   - $serverInBin');
      print('   - $serverInServer');
    } else if (Platform.isMacOS) {
      // macOS: Check in app bundle
      final exePath = Platform.resolvedExecutable;
      final appDir = p.dirname(exePath);
      
      final serverInBin = p.join(appDir, 'medicore-server');
      if (await File(serverInBin).exists()) {
        return serverInBin;
      }
    } else if (Platform.isLinux) {
      // Linux: Check in app directory
      final exePath = Platform.resolvedExecutable;
      final appDir = p.dirname(exePath);
      
      final serverInBin = p.join(appDir, 'medicore-server');
      if (await File(serverInBin).exists()) {
        return serverInBin;
      }
    }
    
    return null;
  }
}
