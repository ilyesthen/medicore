import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/database/app_database.dart';
import 'network_service.dart';

/// Setup state
class SetupState {
  final bool isSetupComplete;
  final bool isServer;
  final String? serverIP;
  final String? serverName;
  final bool isLoading;

  const SetupState({
    this.isSetupComplete = false,
    this.isServer = false,
    this.serverIP,
    this.serverName,
    this.isLoading = true,
  });

  SetupState copyWith({
    bool? isSetupComplete,
    bool? isServer,
    String? serverIP,
    String? serverName,
    bool? isLoading,
  }) {
    return SetupState(
      isSetupComplete: isSetupComplete ?? this.isSetupComplete,
      isServer: isServer ?? this.isServer,
      serverIP: serverIP ?? this.serverIP,
      serverName: serverName ?? this.serverName,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Setup notifier
class SetupNotifier extends StateNotifier<SetupState> {
  SetupNotifier() : super(const SetupState()) {
    _loadSetup();
  }

  Future<void> _loadSetup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if setup_complete is set in preferences
      final prefComplete = prefs.getBool('setup_complete') ?? false;
      final isServer = prefs.getBool('is_server') ?? false;
      final serverIP = prefs.getString('server_ip');
      final serverName = prefs.getString('server_name');
      
      // Also check if database actually exists with data
      bool dbHasData = false;
      try {
        final db = AppDatabase.instance;
        final users = await db.select(db.users).get();
        dbHasData = users.isNotEmpty;
        print('SetupProvider: Database has ${users.length} users');
      } catch (e) {
        print('SetupProvider: Could not read database: $e');
      }
      
      // Setup is complete only if BOTH preference is set AND database has data
      final isComplete = prefComplete && dbHasData;
      print('SetupProvider: prefComplete=$prefComplete, dbHasData=$dbHasData, isComplete=$isComplete');

      state = SetupState(
        isSetupComplete: isComplete,
        isServer: isServer,
        serverIP: serverIP,
        serverName: serverName,
        isLoading: false,
      );

      // If we're a server, start broadcasting
      if (isComplete && isServer && serverName != null) {
        NetworkService.startServerBroadcast(serverName);
      }
    } catch (e) {
      print('SetupProvider: Error loading setup: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> setupAsServer(String serverName) async {
    final prefs = await SharedPreferences.getInstance();
    final ip = await NetworkService.getLocalIP();
    
    await prefs.setBool('setup_complete', true);
    await prefs.setBool('is_server', true);
    await prefs.setString('server_ip', ip);
    await prefs.setString('server_name', serverName);

    await NetworkService.startServerBroadcast(serverName);

    state = SetupState(
      isSetupComplete: true,
      isServer: true,
      serverIP: ip,
      serverName: serverName,
      isLoading: false,
    );
  }

  Future<void> setupAsClient(String serverIP, String serverName) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool('setup_complete', true);
    await prefs.setBool('is_server', false);
    await prefs.setString('server_ip', serverIP);
    await prefs.setString('server_name', serverName);

    state = SetupState(
      isSetupComplete: true,
      isServer: false,
      serverIP: serverIP,
      serverName: serverName,
      isLoading: false,
    );
  }

  Future<void> resetSetup() async {
    NetworkService.stopServerBroadcast();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('setup_complete');
    await prefs.remove('is_server');
    await prefs.remove('server_ip');
    await prefs.remove('server_name');

    state = const SetupState(isLoading: false);
  }
}

/// Provider
final setupProvider = StateNotifierProvider<SetupNotifier, SetupState>((ref) {
  return SetupNotifier();
});

/// Provider to check if setup is needed
final isSetupCompleteProvider = Provider<bool>((ref) {
  return ref.watch(setupProvider).isSetupComplete;
});

/// Provider to check if this instance is a server
final isServerProvider = Provider<bool>((ref) {
  return ref.watch(setupProvider).isServer;
});

/// Provider for server IP (for clients to connect to)
final serverIPProvider = Provider<String?>((ref) {
  return ref.watch(setupProvider).serverIP;
});
