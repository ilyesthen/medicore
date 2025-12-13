import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/app_database.dart';

/// Automatic database backup service
/// Creates backups every 5 minutes and on app close
class DatabaseBackupService {
  static DatabaseBackupService? _instance;
  static DatabaseBackupService get instance => _instance ??= DatabaseBackupService._();
  
  DatabaseBackupService._();
  
  Timer? _backupTimer;
  bool _isRunning = false;
  
  /// Start automatic backups (call once at app startup for admin mode)
  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;
    
    print('💾 Database backup service started');
    
    // Create initial backup
    await createBackup();
    
    // Schedule backup every 5 minutes
    _backupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      createBackup();
    });
  }
  
  /// Stop automatic backups
  void stop() {
    _backupTimer?.cancel();
    _backupTimer = null;
    _isRunning = false;
    print('💾 Database backup service stopped');
  }
  
  /// Create a backup now
  Future<bool> createBackup() async {
    try {
      final dbFile = await DatabasePath.getDbFile();
      if (!await dbFile.exists()) {
        print('⚠️ No database to backup');
        return false;
      }
      
      // Get backup directory
      final backupDir = await _getBackupDirectory();
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      // Create timestamped backup
      final now = DateTime.now();
      final timestamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}';
      final backupPath = p.join(backupDir.path, 'medicore_backup_$timestamp.db');
      
      // Also keep a "latest" backup that's always current
      final latestPath = p.join(backupDir.path, 'medicore_latest.db');
      
      // Copy database
      await dbFile.copy(backupPath);
      await dbFile.copy(latestPath);
      
      final size = await dbFile.length();
      final sizeMB = (size / 1024 / 1024).toStringAsFixed(2);
      print('✅ Backup created: $backupPath ($sizeMB MB)');
      
      // Clean old backups (keep last 10)
      await _cleanOldBackups(backupDir);
      
      return true;
    } catch (e) {
      print('❌ Backup failed: $e');
      return false;
    }
  }
  
  /// Get backup directory
  Future<Directory> _getBackupDirectory() async {
    final appDir = await getApplicationSupportDirectory();
    return Directory(p.join(appDir.path, 'backups'));
  }
  
  /// Clean old backups, keep only the 10 most recent
  Future<void> _cleanOldBackups(Directory backupDir) async {
    try {
      final files = await backupDir
          .list()
          .where((f) => f is File && f.path.contains('medicore_backup_'))
          .cast<File>()
          .toList();
      
      if (files.length <= 10) return;
      
      // Sort by modification time (oldest first)
      files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
      
      // Delete oldest files
      final toDelete = files.take(files.length - 10);
      for (final file in toDelete) {
        await file.delete();
        print('🗑️ Deleted old backup: ${p.basename(file.path)}');
      }
    } catch (e) {
      print('⚠️ Failed to clean old backups: $e');
    }
  }
  
  /// Get list of available backups
  Future<List<File>> getBackups() async {
    try {
      final backupDir = await _getBackupDirectory();
      if (!await backupDir.exists()) return [];
      
      final files = await backupDir
          .list()
          .where((f) => f is File && f.path.endsWith('.db'))
          .cast<File>()
          .toList();
      
      // Sort by modification time (newest first)
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      
      return files;
    } catch (e) {
      print('❌ Failed to list backups: $e');
      return [];
    }
  }
  
  /// Restore from a backup file
  Future<bool> restoreFromBackup(File backupFile) async {
    try {
      if (!await backupFile.exists()) return false;
      
      // Close current database
      if (AppDatabase.isInitialized) {
        await AppDatabase.instance.close();
      }
      
      // Replace current database with backup
      final success = await DatabasePath.importDatabase(backupFile.path);
      
      if (success) {
        print('✅ Database restored from backup');
        await AppDatabase.reinitialize(skipMigrations: true);
      }
      
      return success;
    } catch (e) {
      print('❌ Restore failed: $e');
      return false;
    }
  }
}
