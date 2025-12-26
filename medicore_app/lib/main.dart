import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'src/core/ui/window_init.dart';
import 'src/core/theme/medicore_colors.dart';
import 'src/core/api/grpc_client.dart';
import 'src/features/auth/presentation/auth_provider.dart';
import 'src/features/auth/presentation/login_screen_french.dart';
import 'src/features/auth/presentation/room_selection_wrapper.dart';
import 'src/features/dashboard/presentation/admin_dashboard.dart';
import 'src/features/setup/presentation/setup_wizard_simplified.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// MediCore Professional Client Application
/// Version 5.0.0 - Client-Server Architecture
const String appVersion = '5.0.0';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize locale for date formatting
  await initializeDateFormatting('fr_FR', null);
  
  // Enable wakelock to prevent PC from sleeping
  await WakelockPlus.enable();
  
  // Initialize window (desktop)
  initializeWindow();
  
  // Run app with error handling
  runApp(
    ProviderScope(
      child: const MediCoreApp(),
    ),
  );
  
  // Configure window after first frame (bitsdojo_window)
  doWhenWindowReady(() {
    const initialSize = Size(1920, 1080);
    appWindow.minSize = const Size(1280, 720);
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.title = 'MediCore v$appVersion';
    appWindow.show();
  });
}

/// Main app widget
class MediCoreApp extends StatelessWidget {
  const MediCoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediCore',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: MediCoreColors.deepNavy,
        colorScheme: ColorScheme.fromSeed(
          seedColor: MediCoreColors.deepNavy,
          primary: MediCoreColors.deepNavy,
        ),
        useMaterial3: true,
      ),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      home: const AppInitializer(),
    );
  }
}

/// Initializes the app and determines which screen to show
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  bool _setupComplete = false;

  @override
  void initState() {
    super.initState();
    _checkSetup();
  }

  Future<void> _checkSetup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if setup has been completed
      final setupComplete = prefs.getBool('setup_complete') ?? false;
      final serverIp = prefs.getString('server_ip');
      final isServer = prefs.getBool('is_server') ?? false;
      
      // CRITICAL: If app is in ADMIN/server mode, force reset to setup
      // The app should NEVER be in server mode - it should connect to REST API
      if (isServer) {
        print('⚠️ App is in ADMIN mode - forcing reset to CLIENT setup');
        await _forceResetToClientMode(prefs);
        setState(() {
          _setupComplete = false;
          _isLoading = false;
        });
        return;
      }
      
      if (setupComplete && serverIp != null && serverIp.isNotEmpty) {
        // Configure client with saved server
        GrpcClientConfig.setServerHost(serverIp);
        GrpcClientConfig.setServerMode(false);
        
        print('✅ App configured as CLIENT connecting to: $serverIp');
        
        setState(() {
          _setupComplete = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _setupComplete = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error checking setup: $e');
      setState(() {
        _setupComplete = false;
        _isLoading = false;
      });
    }
  }
  
  /// Force reset app from ADMIN mode to CLIENT mode
  Future<void> _forceResetToClientMode(SharedPreferences prefs) async {
    print('🔄 Resetting app configuration...');
    // Clear all setup-related preferences
    await prefs.remove('setup_complete');
    await prefs.remove('is_server');
    await prefs.remove('server_name');
    // Keep server_ip in case it's useful, but mark as not complete
    print('✅ Reset complete - app will show setup wizard');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: MediCoreColors.deepNavy,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 24),
              Text(
                'MediCore v$appVersion',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_setupComplete) {
      return SetupWizardSimplified(
        onComplete: () async {
          // Reload setup status after wizard completes
          await _checkSetup();
        },
      );
    }

    // Setup complete - show main app with reset option
    return AppRouter(
      onResetRequested: () async {
        final prefs = await SharedPreferences.getInstance();
        await _forceResetToClientMode(prefs);
        setState(() {
          _setupComplete = false;
        });
      },
    );
  }
}

/// Routes between login and main app
class AppRouter extends ConsumerWidget {
  final VoidCallback? onResetRequested;
  
  const AppRouter({super.key, this.onResetRequested});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authStateProvider);

    if (state.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state.errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${state.errorMessage}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(authStateProvider.notifier).logout();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.user == null) {
      // Not logged in - show login screen
      return const LoginScreenFrench();
    } else if (state.selectedRoom == null &&
        (state.user!.role.toLowerCase() == 'médecin' ||
            state.user!.role.toLowerCase() == 'secrétaire' ||
            state.user!.role.toLowerCase() == 'assistant(e)')) {
      // Logged in but no room selected (for roles that need rooms)
      return const RoomSelectionWrapper();
    } else {
      // Fully authenticated - show dashboard
      return const AdminDashboard();
    }
  }
}

/// Global error handler for unhandled exceptions
void handleGlobalError(Object error, StackTrace stack) {
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('❌ UNHANDLED ERROR');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('Error: $error');
  print('Stack trace:');
  print(stack);
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
}
