import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'src/core/ui/canvas_scaler.dart';
import 'src/core/ui/scroll_behavior.dart';
import 'src/core/ui/window_init.dart';
import 'src/core/theme/medicore_colors.dart';
import 'src/core/api/grpc_client.dart';
import 'src/core/services/admin_broadcast_service.dart';
import 'src/features/auth/presentation/auth_provider.dart';
import 'src/features/auth/presentation/login_screen_french.dart';
import 'src/features/auth/presentation/room_selection_wrapper.dart';
import 'src/features/dashboard/presentation/admin_dashboard.dart';
import 'src/features/setup/presentation/setup_wizard.dart';

/// Check if setup has been completed by looking for config file
Future<bool> _isSetupComplete() async {
  try {
    final appDir = await getApplicationSupportDirectory();
    final configFile = File(p.join(appDir.path, 'medicore_config.txt'));
    return configFile.existsSync();
  } catch (e) {
    return false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  Intl.defaultLocale = 'fr';
  
  // Check if setup is needed
  final setupDone = await _isSetupComplete();
  
  // If setup is done and we're in admin mode, start broadcasting
  if (setupDone && !kIsWeb) {
    _startAdminBroadcastIfNeeded();
  }
  
  // Initialize gRPC client configuration
  await GrpcClientConfig.initialize();
  
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

/// Start admin broadcast service if this instance is configured as admin
Future<void> _startAdminBroadcastIfNeeded() async {
  try {
    final appDir = await getApplicationSupportDirectory();
    final configFile = File(p.join(appDir.path, 'medicore_config.txt'));
    
    if (await configFile.exists()) {
      final config = jsonDecode(await configFile.readAsString());
      if (config['mode'] == 'admin' && config['ip'] != null) {
        await AdminBroadcastService.instance.start(config['ip']);
        print('✓ Admin broadcast service started');
      }
    }
  } catch (e) {
    print('Error starting broadcast: $e');
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

  void _onSetupComplete() {
    setState(() => _needsSetup = false);
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
      ),
    );
  }
}

/// Main app after setup is complete
class _MainApp extends ConsumerWidget {
  const _MainApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    if (!authState.isAuthenticated) {
      return const LoginScreenFrench();
    }
    
    return authState.isAdmin
        ? const AdminDashboard()
        : const RoomSelectionWrapper();
  }
}
