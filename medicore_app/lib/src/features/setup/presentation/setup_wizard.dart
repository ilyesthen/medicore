import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/database/app_database.dart';
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
        'version': '3.0.0',
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
    setState(() { _isWorking = true; _status = 'Connexion à ${server.name}...'; });
    
    try {
      // Save config to file
      final appDir = await getApplicationSupportDirectory();
      if (!await appDir.exists()) await appDir.create(recursive: true);
      
      final config = {
        'version': '3.0.0',
        'mode': 'client',
        'serverIp': server.ip,
        'serverName': server.name,
        'date': DateTime.now().toIso8601String()
      };
      final configFile = File(p.join(appDir.path, 'medicore_config.txt'));
      await configFile.writeAsString(jsonEncode(config));
      
      // Save to SharedPreferences (for GrpcClientConfig)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_server', false);  // CLIENT MODE
      await prefs.setString('server_ip', server.ip);
      
      // Configure gRPC client
      GrpcClientConfig.setServerMode(false);
      GrpcClientConfig.setServerHost(server.ip);
      
      // IMPORTANT: Set client mode flag to prevent local database creation
      AppDatabase.setClientMode(true);
      
      print('✓ Client configured: ${server.name} at ${server.ip}');
      print('✓ gRPC client mode enabled, connecting to ${server.ip}:50051');
      print('✓ Local database DISABLED - using gRPC only');
      
      setState(() => _status = '✓ Connecté à ${server.name}');
      
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) widget.onComplete();
      
    } catch (e) {
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

  Future<List<_ServerInfo>> _discoverServers() async {
    final servers = <_ServerInfo>[];
    final seen = <String>{};
    
    try {
      // Listen for UDP broadcasts
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 45678, reuseAddress: true);
      socket.broadcastEnabled = true;
      
      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final dg = socket.receive();
          if (dg != null) {
            try {
              final data = jsonDecode(utf8.decode(dg.data));
              if (data['type'] == 'medicore' && !seen.contains(data['ip'])) {
                seen.add(data['ip']);
                servers.add(_ServerInfo(data['name'], data['ip']));
                if (mounted) setState(() {
                  _foundServers = List.from(servers);
                  _status = '${servers.length} serveur(s) trouvé(s)...';
                });
              }
            } catch (_) {}
          }
        }
      });
      
      // Get local IP and subnet
      final localIP = await _getLocalIP();
      final subnet = localIP.substring(0, localIP.lastIndexOf('.'));
      
      if (mounted) setState(() => _status = 'Scan réseau $subnet.0/24...');
      
      // Scan local subnet with longer timeout
      int scanned = 0;
      for (int i = 1; i <= 254; i++) {
        final ip = '$subnet.$i';
        if (ip == localIP || seen.contains(ip)) continue;
        
        Socket.connect(ip, 50051, timeout: const Duration(milliseconds: 500))
            .then((s) {
              s.destroy();
              if (!seen.contains(ip)) {
                seen.add(ip);
                servers.add(_ServerInfo('MediCore Admin', ip));
                if (mounted) setState(() {
                  _foundServers = List.from(servers);
                  _status = '${servers.length} serveur(s) trouvé(s)!';
                });
              }
            })
            .catchError((_) {});
        
        scanned++;
        if (scanned % 50 == 0 && mounted) {
          setState(() => _status = 'Scan en cours... $scanned/254');
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
      
      // Wait up to 10 seconds for all responses
      if (mounted) setState(() => _status = 'Attente des réponses...');
      await Future.delayed(const Duration(seconds: 10));
      socket.close();
      
      return servers;
    } catch (e) {
      print('Discovery error: $e');
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
