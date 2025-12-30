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
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'src/core/ui/canvas_scaler.dart';
import 'src/core/ui/scroll_behavior.dart';
import 'src/core/ui/window_init.dart';
import 'src/core/theme/medicore_colors.dart';
import 'src/core/api/connection_manager.dart';
import 'src/features/auth/presentation/auth_provider.dart';
import 'src/features/auth/presentation/login_screen_french.dart';
import 'src/features/auth/presentation/room_selection_wrapper.dart';
import 'src/features/dashboard/presentation/admin_dashboard.dart';
import 'src/features/setup/presentation/setup_wizard.dart';
import 'src/features/messages/services/notification_service.dart';

/// Current app version
const String _currentAppVersion = '5.1.0';

/// Check if setup has been completed
Future<bool> _isSetupComplete() async {
  try {
    final appDir = await getApplicationSupportDirectory();
    final configFile = File(p.join(appDir.path, 'medicore_config.txt'));
    
    if (!configFile.existsSync()) {
      print('❌ Setup incomplete: No config file');
      return false;
    }
    
    final config = jsonDecode(await configFile.readAsString());
    
    if (config['serverIp'] == null || config['serverIp'].toString().isEmpty) {
      print('❌ Setup incomplete: No server IP configured');
      await configFile.delete();
      return false;
    }
    
    print('✓ Setup complete: Server IP: ${config['serverIp']}');
    return true;
  } catch (e) {
    print('❌ Setup check error: $e');
    return false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize French locale
  await initializeDateFormatting('fr_FR', null);
  Intl.defaultLocale = 'fr_FR';
  
  // Check if setup is needed
  final setupDone = await _isSetupComplete();
  
  // Initialize notification service
  print('🔊 Initializing notification service...');
  await NotificationService().initialize();
  
  // Initialize connection manager (loads saved config + connects)
  if (setupDone) {
    print('🔌 Initializing connection manager...');
    final connected = await ConnectionManager.instance.initialize();
    if (connected) {
      print('✅ Connected to server');
    } else {
      print('⚠️ Could not connect - will retry automatically');
    }
  }
  
  runApp(
    ProviderScope(
      child: MediCoreApp(needsSetup: !setupDone),
    ),
  );
  
  // Initialize window (desktop only)
  if (!kIsWeb) {
    initializeWindow();
    await initializeWindowManager();
  }
}

/// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MediCoreApp extends ConsumerStatefulWidget {
  final bool needsSetup;
  const MediCoreApp({super.key, required this.needsSetup});

  @override
  ConsumerState<MediCoreApp> createState() => _MediCoreAppState();
}

class _MediCoreAppState extends ConsumerState<MediCoreApp> with WindowListener {
  late bool _needsSetup;

  @override
  void initState() {
    super.initState();
    _needsSetup = widget.needsSetup;
    if (!kIsWeb) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowClose() async {
    final shouldClose = await _showExitConfirmation();
    if (shouldClose) {
      await windowManager.destroy();
    }
  }

  Future<bool> _showExitConfirmation() async {
    final result = await showDialog<bool>(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5F5F5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF1A237E), width: 2),
        ),
        title: Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.orange[700], size: 28),
            const SizedBox(width: 12),
            const Text(
              'Quitter l\'application',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
            ),
          ],
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir quitter Thaziri ?\n\nToutes les modifications non enregistrées seront perdues.',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ANNULER', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('QUITTER', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _onSetupComplete() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _needsSetup = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CanvasScaler(
      child: MaterialApp(
        navigatorKey: navigatorKey,
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
        builder: (context, child) {
          ErrorWidget.builder = (FlutterErrorDetails details) {
            print('❌ FLUTTER ERROR: ${details.exception}');
            return Scaffold(
              backgroundColor: MediCoreColors.canvasGrey,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bug_report, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Erreur inattendue', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('${details.exception}', style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(onPressed: () => exit(0), child: const Text('Redémarrer')),
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

/// Main app with connection status monitoring
class _MainApp extends ConsumerWidget {
  const _MainApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch connection status
    final connectionState = ref.watch(connectionStateProvider);
    
    return Stack(
      children: [
        // Main content
        _buildMainContent(context, ref),
        
        // Connection status banner (shows when disconnected/reconnecting)
        connectionState.when(
          data: (state) {
            if (state.status == ConnectionStatus.connected) {
              return const SizedBox.shrink();
            }
            return _ConnectionBanner(state: state);
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context, WidgetRef ref) {
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
      print('Stack: $stack');
      
      return Scaffold(
        backgroundColor: MediCoreColors.canvasGrey,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Erreur de chargement', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Erreur: $e', style: const TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => exit(0), child: const Text('Redémarrer l\'application')),
            ],
          ),
        ),
      );
    }
  }
}

/// Connection status banner - shows at top when disconnected
class _ConnectionBanner extends StatelessWidget {
  final ServerConnectionState state;
  
  const _ConnectionBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final isReconnecting = state.status == ConnectionStatus.reconnecting;
    
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isReconnecting 
                  ? [Colors.orange.shade600, Colors.orange.shade800]
                  : [Colors.red.shade600, Colors.red.shade800],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                if (isReconnecting)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(Icons.cloud_off, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isReconnecting ? 'Reconnexion en cours...' : 'Connexion perdue',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (state.reconnectAttempts > 0)
                        Text(
                          'Tentative ${state.reconnectAttempts}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Force immediate reconnect
                    ConnectionManager.instance.cancelReconnect();
                    ConnectionManager.instance.connect(
                      state.serverIP!,
                      state.serverName ?? 'MediCore Server',
                    );
                  },
                  child: const Text(
                    'RÉESSAYER',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
