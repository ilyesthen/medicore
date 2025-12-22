import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/admin_broadcast_service.dart';
import '../../../core/services/grpc_server_launcher.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/api/grpc_client.dart';

/// Setup Wizard - Choose Admin (with database) or Client (connects to Admin)
class SetupWizard extends StatefulWidget {
  final VoidCallback onComplete;
  const SetupWizard({super.key, required this.onComplete});

  @override
  State<SetupWizard> createState() => _SetupWizardState();
}

class _SetupWizardState extends State<SetupWizard> {
  // null = choosing, 'admin' = admin setup, 'client' = client setup
  String? _mode;
  String _status = '';
  bool _isWorking = false;
  String? _selectedDbPath;
  List<_ServerInfo> _foundServers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MediCoreColors.deepNavy,
      body: Center(
        child: Container(
          width: 550,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30)],
          ),
          child: _mode == null ? _buildModeSelection() : 
                 _mode == 'admin' ? _buildAdminSetup() : _buildClientSetup(),
        ),
      ),
    );
  }

  /// Mode selection screen - Admin or Client
  Widget _buildModeSelection() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Logo
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF0D47A1)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.local_hospital, color: Colors.white, size: 56),
      ),
      const SizedBox(height: 24),
      const Text('MediCore', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: MediCoreColors.deepNavy)),
      const SizedBox(height: 8),
      const Text('Système de Gestion Médicale', style: TextStyle(fontSize: 14, color: Colors.grey)),
      const SizedBox(height: 40),
      
      // Two options
      Row(children: [
        // ADMIN
        Expanded(child: _ModeCard(
          icon: Icons.dns,
          title: 'ADMIN',
          subtitle: 'Poste principal\nBase de données locale',
          color: const Color(0xFF2E7D32),
          onTap: () => setState(() => _mode = 'admin'),
        )),
        const SizedBox(width: 16),
        // CLIENT
        Expanded(child: _ModeCard(
          icon: Icons.computer,
          title: 'CLIENT',
          subtitle: 'Se connecter au\nposte Admin',
          color: const Color(0xFF1565C0),
          onTap: () {
            setState(() => _mode = 'client');
            _scanForServers();
          },
        )),
      ]),
      
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(
            'Choisissez ADMIN sur le poste principal (avec la base de données).\nLes autres postes choisiront CLIENT.',
            style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
          )),
        ]),
      ),
    ]);
  }

  /// Admin setup - import database
  Widget _buildAdminSetup() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Header with back button
      Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isWorking ? null : () => setState(() { _mode = null; _status = ''; }),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.dns, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        const Text('Configuration Admin', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 24),
      
      // Status
      if (_status.isNotEmpty) _buildStatusBox(),
      
      // Select database
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(children: [
          const Icon(Icons.storage, size: 40, color: Color(0xFF2E7D32)),
          const SizedBox(height: 12),
          const Text('Base de Données', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isWorking ? null : _selectDatabase,
              icon: const Icon(Icons.folder_open),
              label: Text(_selectedDbPath != null 
                  ? p.basename(_selectedDbPath!) 
                  : 'Sélectionner le fichier .db'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedDbPath != null ? const Color(0xFF2E7D32) : Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          
          if (_selectedDbPath != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isWorking ? null : _importAndStartAdmin,
                icon: const Icon(Icons.rocket_launch),
                label: const Text('DÉMARRER COMME ADMIN', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ]),
      ),
    ]);
  }

  /// Client setup - find and connect to admin
  Widget _buildClientSetup() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Header with back button
      Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isWorking ? null : () => setState(() { _mode = null; _status = ''; _foundServers = []; }),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF1565C0), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.computer, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        const Text('Connexion Client', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 24),
      
      // Status
      if (_status.isNotEmpty) _buildStatusBox(),
      
      // Scan button
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isWorking ? null : _scanForServers,
          icon: _isWorking 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.wifi_find),
          label: Text(_isWorking ? 'Recherche en cours...' : 'Rechercher le serveur Admin'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
      const SizedBox(height: 16),
      
      // Server list
      Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _foundServers.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.search, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(_isWorking ? 'Recherche...' : 'Aucun serveur trouvé', 
                     style: TextStyle(color: Colors.grey.shade600)),
                if (!_isWorking) Text('Vérifiez que le poste Admin est démarré', 
                     style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ]))
            : ListView.builder(
                itemCount: _foundServers.length,
                itemBuilder: (ctx, i) {
                  final server = _foundServers[i];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF2E7D32),
                      child: Icon(Icons.dns, color: Colors.white, size: 20),
                    ),
                    title: Text(server.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(server.ip),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _connectToServer(server),
                  );
                },
              ),
      ),
    ]);
  }

  Widget _buildStatusBox() {
    final isSuccess = _status.contains('✓');
    final isError = _status.toLowerCase().contains('erreur');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.shade50 : (isError ? Colors.red.shade50 : Colors.blue.shade50),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSuccess ? Colors.green : (isError ? Colors.red : Colors.blue)),
      ),
      child: Row(children: [
        if (_isWorking && !isSuccess && !isError)
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
        else
          Icon(isSuccess ? Icons.check_circle : (isError ? Icons.error : Icons.info),
               color: isSuccess ? Colors.green : (isError ? Colors.red : Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: Text(_status, style: const TextStyle(fontSize: 13))),
      ]),
    );
  }

  Future<void> _selectDatabase() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db', 'sqlite', 'sqlite3'],
        dialogTitle: 'Sélectionner votre base de données MediCore',
      );
      
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final file = File(path);
        final size = await file.length();
        final sizeMB = (size / 1024 / 1024).toStringAsFixed(1);
        
        setState(() {
          _selectedDbPath = path;
          _status = 'Fichier: ${p.basename(path)} ($sizeMB MB)';
        });
      }
    } catch (e) {
      setState(() => _status = 'Erreur: $e');
    }
  }

  Future<void> _importAndStartAdmin() async {
    if (_selectedDbPath == null) return;
    
    setState(() { _isWorking = true; _status = 'Importation...'; });

    try {
      final appDir = await getApplicationSupportDirectory();
      final destPath = p.join(appDir.path, 'medicore.db');
      
      // Ensure directory exists
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      
      // Copy database
      setState(() => _status = 'Copie de la base de données...');
      final sourceFile = File(_selectedDbPath!);
      final destFile = File(destPath);
      if (await destFile.exists()) await destFile.delete();
      await sourceFile.copy(destPath);
      
      // Verify copy
      final newSize = await File(destPath).length();
      final sourceSize = await sourceFile.length();
      if (newSize != sourceSize) throw Exception('Copie échouée');
      
      // Reinitialize and verify
      setState(() => _status = 'Vérification de la base...');
      await AppDatabase.reinitialize(skipMigrations: true);
      final db = AppDatabase.instance;
      final users = await db.select(db.users).get();
      final patients = await db.select(db.patients).get();
      
      setState(() => _status = '✓ ${users.length} utilisateurs, ${patients.length} patients');
      
      // Get local IP
      final ip = await _getLocalIP();
      
      // Save config to file (with version for upgrade detection)
      final config = {
        'version': '3.7.2',
        'mode': 'admin', 
        'ip': ip, 
        'date': DateTime.now().toIso8601String()
      };
      final configFile = File(p.join(appDir.path, 'medicore_config.txt'));
      await configFile.writeAsString(jsonEncode(config));
      
      // Save to SharedPreferences (for GrpcClientConfig)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_server', true);  // ADMIN MODE
      await prefs.setString('server_ip', ip);
      
      // Configure gRPC server
      GrpcClientConfig.setServerMode(true);
      GrpcClientConfig.setServerHost(ip);
      
      print('✓ Admin configured at $ip');
      print('✓ gRPC server mode enabled');
      
      // Start gRPC server for clients
      setState(() => _status = 'Démarrage du serveur gRPC...');
      final serverStarted = await GrpcServerLauncher.start();
      if (serverStarted) {
        print('✅ gRPC server started - Clients can now connect!');
      } else {
        print('⚠️ gRPC server not started - Clients will not be able to connect');
      }
      
      // Start persistent broadcast service
      await AdminBroadcastService.instance.start(ip);
      
      setState(() => _status = '✓ Configuration terminée!');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) widget.onComplete();
      
    } catch (e) {
      setState(() { _isWorking = false; _status = 'Erreur: $e'; });
    }
  }

  Future<void> _scanForServers() async {
    setState(() { _isWorking = true; _status = 'Recherche sur le réseau...'; _foundServers = []; });
    
    try {
      final servers = await _discoverServers();
      setState(() {
        _foundServers = servers;
        _isWorking = false;
        _status = servers.isEmpty ? 'Aucun serveur trouvé' : '${servers.length} serveur(s) trouvé(s)';
      });
    } catch (e) {
      setState(() { _isWorking = false; _status = 'Erreur: $e'; });
    }
  }

  Future<void> _connectToServer(_ServerInfo server) async {
    setState(() { _isWorking = true; _status = 'Vérification de la connexion...'; });
    
    try {
      // === Step 1: Verify connection to gRPC server ===
      print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔗 CONNECTING TO SERVER: ${server.ip}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      setState(() => _status = 'Test de connexion au serveur...');
      
      bool canConnect = false;
      try {
        final socket = await Socket.connect(
          server.ip,
          _grpcPort,
          timeout: const Duration(seconds: 5),
        );
        socket.destroy();
        canConnect = true;
        print('✅ TCP connection to gRPC port successful');
      } catch (e) {
        print('❌ Cannot connect to gRPC port: $e');
      }
      
      if (!canConnect) {
        setState(() {
          _isWorking = false;
          _status = 'Erreur: Impossible de se connecter au serveur.\n\n'
              'Vérifiez que:\n'
              '• Le PC Admin est allumé\n'
              '• MediCore est lancé sur le PC Admin\n'
              '• Les deux PCs sont sur le même réseau';
        });
        return;
      }
      
      // === Step 2: Save configuration ===
      setState(() => _status = 'Sauvegarde de la configuration...');
      
      final appDir = await getApplicationSupportDirectory();
      if (!await appDir.exists()) await appDir.create(recursive: true);
      
      final config = {
        'version': '3.7.2',
        'mode': 'client',
        'serverIp': server.ip,
        'serverName': server.name,
        'connectedAt': DateTime.now().toIso8601String(),
      };
      final configFile = File(p.join(appDir.path, 'medicore_config.txt'));
      await configFile.writeAsString(jsonEncode(config));
      
      // === Step 3: Configure gRPC client ===
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_server', false);
      await prefs.setString('server_ip', server.ip);
      
      GrpcClientConfig.setServerMode(false);
      GrpcClientConfig.setServerHost(server.ip);
      
      // Prevent local database creation in client mode
      AppDatabase.setClientMode(true);
      
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('✅ CLIENT MODE CONFIGURED');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📡 Server: ${server.name}');
      print('🔗 IP: ${server.ip}:$_grpcPort');
      print('💾 Local database: DISABLED');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      
      setState(() => _status = '✓ Connecté à ${server.name}');
      
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) widget.onComplete();
      
    } catch (e) {
      print('❌ Connection error: $e');
      setState(() { _isWorking = false; _status = 'Erreur: $e'; });
    }
  }

  // Network helpers
  Future<String> _getLocalIP() async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && (addr.address.startsWith('192.168') || addr.address.startsWith('10.'))) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return '127.0.0.1';
  }

  void _startBroadcast(String ip) {
    // Start UDP broadcast for discovery
    RawDatagramSocket.bind(InternetAddress.anyIPv4, 0).then((socket) {
      socket.broadcastEnabled = true;
      final msg = jsonEncode({'type': 'medicore', 'name': 'MediCore Admin', 'ip': ip});
      
      // Broadcast immediately
      try { 
        socket.send(utf8.encode(msg), InternetAddress('255.255.255.255'), 45678);
        print('✓ Broadcasting MediCore Admin at $ip');
      } catch (e) {
        print('Broadcast error: $e');
      }
      
      // Then keep broadcasting every second
      Timer.periodic(const Duration(seconds: 1), (_) {
        try { 
          socket.send(utf8.encode(msg), InternetAddress('255.255.255.255'), 45678);
        } catch (_) {}
      });
    });
  }

  /// Discovery constants (must match AdminBroadcastService)
  static const int _broadcastPort = 45678;
  static const int _discoveryPort = 45677;
  static const int _grpcPort = 50051;
  static const String _discoverRequest = 'MEDICORE_DISCOVER';
  static const String _discoverResponse = 'MEDICORE_SERVER';

  /// Enterprise-grade server discovery using multiple methods:
  /// 1. Active discovery: Send MEDICORE_DISCOVER request, wait for response
  /// 2. Passive discovery: Listen for admin broadcast on port 45678
  /// 3. Fallback: Scan subnet for gRPC port 50051
  Future<List<_ServerInfo>> _discoverServers() async {
    final servers = <_ServerInfo>[];
    final seen = <String>{};
    
    void addServer(String name, String ip, String? computerName) {
      if (!seen.contains(ip)) {
        seen.add(ip);
        final displayName = computerName != null ? '$name ($computerName)' : name;
        servers.add(_ServerInfo(displayName, ip));
        if (mounted) setState(() {
          _foundServers = List.from(servers);
          _status = '${servers.length} serveur(s) trouvé(s)!';
        });
      }
    }
    
    try {
      print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔍 STARTING SERVER DISCOVERY');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      // === METHOD 1: Active Discovery (Request/Response) ===
      if (mounted) setState(() => _status = 'Envoi de requête de découverte...');
      print('📡 Method 1: Sending active discovery request...');
      
      RawDatagramSocket? activeSocket;
      try {
        activeSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
        activeSocket.broadcastEnabled = true;
        
        // Listen for responses
        activeSocket.listen((event) {
          if (event == RawSocketEvent.read) {
            final dg = activeSocket!.receive();
            if (dg != null) {
              try {
                final data = jsonDecode(utf8.decode(dg.data));
                if (data['type'] == _discoverResponse) {
                  print('✅ Active discovery response from ${dg.address.address}');
                  addServer(
                    data['name'] ?? 'MediCore Admin',
                    data['ip'] ?? dg.address.address,
                    data['computerName'],
                  );
                }
              } catch (_) {}
            }
          }
        });
        
        // Send discovery request to broadcast
        activeSocket.send(
          utf8.encode(_discoverRequest),
          InternetAddress('255.255.255.255'),
          _discoveryPort,
        );
        
        // Also try subnet-specific broadcast
        final localIP = await _getLocalIP();
        if (localIP != '127.0.0.1') {
          final parts = localIP.split('.');
          if (parts.length == 4) {
            final subnetBroadcast = '${parts[0]}.${parts[1]}.${parts[2]}.255';
            activeSocket.send(
              utf8.encode(_discoverRequest),
              InternetAddress(subnetBroadcast),
              _discoveryPort,
            );
            print('📤 Sent to $subnetBroadcast:$_discoveryPort');
          }
        }
        
        // Wait for responses
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        print('⚠️ Active discovery error: $e');
      }
      
      // === METHOD 2: Passive Discovery (Listen for Broadcasts) ===
      if (mounted) setState(() => _status = 'Écoute des diffusions...');
      print('📻 Method 2: Listening for passive broadcasts...');
      
      RawDatagramSocket? passiveSocket;
      try {
        passiveSocket = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4,
          _broadcastPort,
          reuseAddress: true,
        );
        passiveSocket.broadcastEnabled = true;
        
        passiveSocket.listen((event) {
          if (event == RawSocketEvent.read) {
            final dg = passiveSocket!.receive();
            if (dg != null) {
              try {
                final data = jsonDecode(utf8.decode(dg.data));
                if (data['type'] == 'medicore' && data['ip'] != null) {
                  print('✅ Passive broadcast from ${dg.address.address}');
                  addServer(
                    data['name'] ?? 'MediCore Admin',
                    data['ip'],
                    data['computerName'],
                  );
                }
              } catch (_) {}
            }
          }
        });
        
        // Wait for broadcasts
        await Future.delayed(const Duration(seconds: 3));
      } catch (e) {
        print('⚠️ Passive discovery error: $e');
      }
      
      // === METHOD 3: Fallback - Subnet Port Scan ===
      if (servers.isEmpty) {
        print('🔎 Method 3: Fallback subnet scan...');
        final localIP = await _getLocalIP();
        
        if (localIP != '127.0.0.1') {
          final subnet = localIP.substring(0, localIP.lastIndexOf('.'));
          if (mounted) setState(() => _status = 'Scan $subnet.0/24...');
          
          // Scan common IPs first (1-10, then gateway-like addresses)
          final priorityIPs = [
            ...List.generate(10, (i) => '$subnet.${i + 1}'),
            '$subnet.100', '$subnet.101', '$subnet.200', '$subnet.254',
          ];
          
          for (final ip in priorityIPs) {
            if (ip == localIP || seen.contains(ip)) continue;
            try {
              final socket = await Socket.connect(ip, _grpcPort, 
                  timeout: const Duration(milliseconds: 300));
              socket.destroy();
              print('✅ Found gRPC server at $ip');
              addServer('MediCore Admin', ip, null);
            } catch (_) {}
          }
          
          // If still nothing, do full scan
          if (servers.isEmpty) {
            if (mounted) setState(() => _status = 'Scan complet en cours...');
            for (int i = 1; i <= 254; i++) {
              final ip = '$subnet.$i';
              if (ip == localIP || seen.contains(ip)) continue;
              
              Socket.connect(ip, _grpcPort, timeout: const Duration(milliseconds: 200))
                  .then((s) {
                    s.destroy();
                    print('✅ Found gRPC server at $ip (scan)');
                    addServer('MediCore Admin', ip, null);
                  })
                  .catchError((_) {});
            }
            await Future.delayed(const Duration(seconds: 3));
          }
        }
      }
      
      // Cleanup
      activeSocket?.close();
      passiveSocket?.close();
      
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('✅ Discovery complete: ${servers.length} server(s) found');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      
      return servers;
    } catch (e) {
      print('❌ Discovery error: $e');
    }
    return servers;
  }

}

class _ServerInfo {
  final String name;
  final String ip;
  _ServerInfo(this.name, this.ip);
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2),
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 40),
            ),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ]),
        ),
      ),
    );
  }
}
