import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Setup state - PRO ARCHITECTURE
/// All instances connect to the Go backend server
class SetupState {
  final bool isSetupComplete;
  final String? serverIP;
  final String? serverName;
  final bool isLoading;

  const SetupState({
    this.isSetupComplete = false,
    this.serverIP,
    this.serverName,
    this.isLoading = true,
  });

  SetupState copyWith({
    bool? isSetupComplete,
    String? serverIP,
    String? serverName,
    bool? isLoading,
  }) {
    return SetupState(
      isSetupComplete: isSetupComplete ?? this.isSetupComplete,
      serverIP: serverIP ?? this.serverIP,
      serverName: serverName ?? this.serverName,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Setup notifier - manages server connection setup
class SetupNotifier extends StateNotifier<SetupState> {
  SetupNotifier() : super(const SetupState()) {
    _loadSetup();
  }

  Future<void> _loadSetup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final serverIP = prefs.getString('server_ip');
      final serverName = prefs.getString('server_name');
      
      // Setup is complete if we have a server IP configured
      final isComplete = serverIP != null && serverIP.isNotEmpty;
      
      if (isComplete) {
        print('✓ SetupProvider: Connected to server $serverName at $serverIP');
      } else {
        print('⚠️ SetupProvider: No server configured - setup required');
      }

      state = SetupState(
        isSetupComplete: isComplete,
        serverIP: serverIP,
        serverName: serverName,
        isLoading: false,
      );
    } catch (e) {
      print('❌ SetupProvider: Error loading setup: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Complete setup with server connection
  Future<void> completeSetup(String serverIP, String serverName) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('server_ip', serverIP);
    await prefs.setString('server_name', serverName);

    state = SetupState(
      isSetupComplete: true,
      serverIP: serverIP,
      serverName: serverName,
      isLoading: false,
    );
    
    print('✓ SetupProvider: Setup complete - server $serverName at $serverIP');
  }

  /// Reset setup
  Future<void> resetSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('server_ip');
    await prefs.remove('server_name');

    state = const SetupState(isLoading: false);
    print('✓ SetupProvider: Setup reset');
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

/// Provider for server IP
final serverIPProvider = Provider<String?>((ref) {
  return ref.watch(setupProvider).serverIP;
});
