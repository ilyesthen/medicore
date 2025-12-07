import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'src/core/ui/canvas_scaler.dart';
import 'src/core/ui/scroll_behavior.dart';
import 'src/core/ui/window_init.dart';
import 'src/core/theme/medicore_colors.dart';
import 'src/core/api/grpc_client.dart';
import 'src/core/database/app_database.dart';
import 'src/core/services/admin_broadcast_service.dart';
import 'src/core/services/grpc_server_launcher.dart';
import 'src/features/auth/presentation/auth_provider.dart';
import 'src/features/auth/presentation/login_screen_french.dart';
import 'src/features/auth/presentation/room_selection_wrapper.dart';
import 'src/features/dashboard/presentation/admin_dashboard.dart';
import 'src/features/setup/presentation/setup_wizard.dart';

/// Current app version - bump this to force setup wizard on upgrade
const String _currentAppVersion = '3.1.0';

/// Check if setup has been completed
/// Returns true ONLY if config exists AND database exists (for admin) or server IP is saved (for client)
Future<bool> _isSetupComplete() async {
  try {
    final appDir = await getApplicationSupportDirectory();
    final configFile = File(p.join(appDir.path, 'medicore_config.txt'));
    final dbFile = File(p.join(appDir.path, 'medicore.db'));
    
    // Config must exist
    if (!configFile.existsSync()) {
      print('❌ Setup incomplete: No config file');
      return false;
    }
    
    // Parse config
    final config = jsonDecode(await configFile.readAsString());
    
    // Check version - force setup if version mismatch
    final configVersion = config['version'] ?? '1.0.0';
    if (configVersion != _currentAppVersion) {
      print('⚠️ Version mismatch: config=$configVersion, app=$_currentAppVersion');
      print('🔄 Clearing old config to force fresh setup...');
      await configFile.delete();
      if (dbFile.existsSync()) {
        await dbFile.delete();
      }
      return false;
    }
    
    final mode = config['mode'];
    
    if (mode == 'admin') {
      // ADMIN: Must have database file
      if (!dbFile.existsSync()) {
        print('❌ Setup incomplete: Admin mode but no database');
        // Clean up invalid config
        await configFile.delete();
        return false;
      }
      print('✓ Setup complete: ADMIN mode with database');
      return true;
    } else if (mode == 'client') {
      // CLIENT: Must have server IP
      if (config['serverIp'] == null || config['serverIp'].toString().isEmpty) {
        print('❌ Setup incomplete: Client mode but no server IP');
        await configFile.delete();
        return false;
      }
      print('✓ Setup complete: CLIENT mode, server: ${config['serverIp']}');
      return true;
    } else {
      print('❌ Setup incomplete: Invalid mode: $mode');
      await configFile.delete();
      return false;
    }
  } catch (e) {
    print('❌ Setup check error: $e');
    return false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize French locale for date formatting
  await initializeDateFormatting('fr_FR', null);
  Intl.defaultLocale = 'fr_FR';
  
  // Check if setup is needed
  final setupDone = await _isSetupComplete();
  
  // If setup is done and we're in admin mode, start broadcasting
  if (setupDone && !kIsWeb) {
    _startAdminBroadcastIfNeeded();
  }
  
  // Initialize gRPC client configuration
  await GrpcClientConfig.initialize();
  
  // Set client mode flag to prevent local database creation in client mode
  if (!GrpcClientConfig.isServer) {
    AppDatabase.setClientMode(true);
    print('📱 Running in CLIENT mode - local database disabled');
  } else {
    AppDatabase.setClientMode(false);
    print('🖥️ Running in ADMIN mode - local database enabled');
  }
  
  runApp(
    ProviderScope(
      child: MediCoreApp(needsSetup: !setupDone),
    ),
  );
  
  // Initialize custom window (desktop platforms only)
  if (!kIsWeb) {
    initializeWindow();
  }
}

/// Start admin services (gRPC server + broadcast) if this instance is configured as admin
Future<void> _startAdminBroadcastIfNeeded() async {
  try {
    final appDir = await getApplicationSupportDirectory();
    final configFile = File(p.join(appDir.path, 'medicore_config.txt'));
    
    if (await configFile.exists()) {
      final config = jsonDecode(await configFile.readAsString());
      if (config['mode'] == 'admin' && config['ip'] != null) {
        // Start gRPC server for client connections
        print('🚀 Starting admin services...');
        final serverStarted = await GrpcServerLauncher.start();
        if (serverStarted) {
          print('✅ gRPC server started on port 50051');
        } else {
          print('⚠️ gRPC server failed to start - Clients cannot connect');
        }
        
        // Start UDP broadcast for client discovery
        await AdminBroadcastService.instance.start(config['ip']);
        print('✅ Admin broadcast service started');
        print('📡 Admin ready to accept client connections!');
      }
    }
  } catch (e) {
    print('❌ Error starting admin services: $e');
  }
}

class MediCoreApp extends ConsumerStatefulWidget {
  final bool needsSetup;
  const MediCoreApp({super.key, required this.needsSetup});

  @override
  ConsumerState<MediCoreApp> createState() => _MediCoreAppState();
}

class _MediCoreAppState extends ConsumerState<MediCoreApp> {
  late bool _needsSetup;

  @override
  void initState() {
    super.initState();
    _needsSetup = widget.needsSetup;
  }

  void _onSetupComplete() async {
    // Give a moment for database/services to fully initialize
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _needsSetup = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CanvasScaler(
      child: MaterialApp(
        title: 'MediCore',
        debugShowCheckedModeBanner: false,
        scrollBehavior: DesktopScrollBehavior(),
        theme: ThemeData(
          useMaterial3: false,
          scaffoldBackgroundColor: MediCoreColors.canvasGrey,
          fontFamily: 'Roboto',
        ),
        home: _needsSetup 
            ? SetupWizard(onComplete: _onSetupComplete)
            : const _MainApp(),
        // Global error handling
        builder: (context, child) {
          ErrorWidget.builder = (FlutterErrorDetails details) {
            print('❌ FLUTTER ERROR CAUGHT: ${details.exception}');
            print('Stack: ${details.stack}');
            return Scaffold(
              backgroundColor: MediCoreColors.canvasGrey,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bug_report, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Erreur inattendue',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${details.exception}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => exit(0),
                      child: const Text('Redémarrer'),
                    ),
                  ],
                ),
              ),
            );
          };
          return child ?? const SizedBox();
        },
      ),
    );
  }
}

/// Main app after setup is complete
class _MainApp extends ConsumerWidget {
  const _MainApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final authState = ref.watch(authStateProvider);
      
      if (!authState.isAuthenticated) {
        return const LoginScreenFrench();
      }
      
      return authState.isAdmin
          ? const AdminDashboard()
          : const RoomSelectionWrapper();
    } catch (e, stack) {
      print('❌ CRITICAL ERROR in _MainApp: $e');
      print('Stack trace: $stack');
      
      // Show error screen instead of crashing
      return Scaffold(
        backgroundColor: MediCoreColors.canvasGrey,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Erreur de chargement',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Erreur: $e',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Force restart by exiting
                  exit(0);
                },
                child: const Text('Redémarrer l\'application'),
              ),
            ],
          ),
        ),
      );
    }
  }
}
