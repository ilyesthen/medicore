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
      
      if (setupComplete && serverIp != null && serverIp.isNotEmpty) {
        // Configure client with saved server
        GrpcClientConfig.setServerHost(serverIp);
        
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
        onComplete: () {
          setState(() {
            _setupComplete = true;
          });
        },
      );
    }

    // Setup complete - show main app
    return const AppRouter();
  }
}

/// Routes between login and main app
class AppRouter extends ConsumerWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (state) {
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
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(authProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
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
