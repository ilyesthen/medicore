import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/core/ui/canvas_scaler.dart';
import 'src/core/ui/scroll_behavior.dart';
import 'src/core/ui/window_init.dart';
import 'src/core/theme/medicore_colors.dart';
import 'src/core/api/grpc_client.dart';
import 'src/features/auth/presentation/auth_provider.dart';
import 'src/features/auth/presentation/login_screen_french.dart';
import 'src/features/auth/presentation/room_selection_wrapper.dart';
import 'src/features/dashboard/presentation/admin_dashboard.dart';
import 'src/features/setup/data/setup_provider.dart';
import 'src/features/setup/presentation/initial_setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize gRPC client configuration
  await GrpcClientConfig.initialize();
  
  runApp(
    const ProviderScope(
      child: MediCoreApp(),
    ),
  );
  
  // Initialize custom window (desktop platforms only)
  if (!kIsWeb) {
    initializeWindow();
  }
}

class MediCoreApp extends ConsumerStatefulWidget {
  const MediCoreApp({super.key});

  @override
  ConsumerState<MediCoreApp> createState() => _MediCoreAppState();
}

class _MediCoreAppState extends ConsumerState<MediCoreApp> {
  // Skip setup in development mode - set to false for production
  static const bool _devMode = true;
  
  bool _setupComplete = false;

  void _onSetupComplete() {
    setState(() => _setupComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(setupProvider);
    final authState = ref.watch(authStateProvider);
    
    return CanvasScaler(
      child: MaterialApp(
        title: 'MediCore',
        debugShowCheckedModeBanner: false,
        
        // Desktop scroll behavior (no bounce)
        scrollBehavior: DesktopScrollBehavior(),
        
        // Minimal theme (Cockpit design handles styling)
        theme: ThemeData(
          useMaterial3: false,
          scaffoldBackgroundColor: MediCoreColors.canvasGrey,
          fontFamily: 'Roboto',
        ),
        
        // Show appropriate screen based on setup and auth state
        home: _buildHome(setupState, authState),
      ),
    );
  }

  Widget _buildHome(SetupState setupState, AuthState authState) {
    // DEV MODE: Skip setup entirely
    if (_devMode) {
      if (!authState.isAuthenticated) {
        return const LoginScreenFrench();
      }
      return authState.isAdmin
          ? const AdminDashboard()
          : const RoomSelectionWrapper();
    }
    
    // Show loading while checking setup
    if (setupState.isLoading) {
      return const Scaffold(
        backgroundColor: MediCoreColors.deepNavy,
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 24),
            Text('Chargement...', style: TextStyle(color: Colors.white70, fontSize: 16)),
          ]),
        ),
      );
    }

    // Show setup screen if not configured
    if (!setupState.isSetupComplete && !_setupComplete) {
      return InitialSetupScreen(onSetupComplete: _onSetupComplete);
    }

    // Show login or dashboard
    if (!authState.isAuthenticated) {
      return const LoginScreenFrench();
    }
    
    return authState.isAdmin
        ? const AdminDashboard()
        : const RoomSelectionWrapper();
  }
}
