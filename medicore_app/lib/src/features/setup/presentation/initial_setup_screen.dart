import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../../core/api/grpc_client.dart';
import '../../../core/database/app_database.dart';
import '../data/network_service.dart';
import '../data/setup_provider.dart';

/// Initial Setup Screen - First run configuration
/// Admin: Creates server + database
/// Client: Detects server on LAN and connects
class InitialSetupScreen extends ConsumerStatefulWidget {
  final VoidCallback onSetupComplete;
  
  const InitialSetupScreen({super.key, required this.onSetupComplete});

  @override
  ConsumerState<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends ConsumerState<InitialSetupScreen> {
  bool _isScanning = false;
  bool _isSettingUp = false;
  String? _selectedServer;
  List<ServerInfo> _discoveredServers = [];
  String _statusMessage = '';
  
  final _serverNameController = TextEditingController(text: 'Cabinet Principal');
  final _adminPasswordController = TextEditingController();

  @override
  void dispose() {
    _serverNameController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  Future<void> _scanForServers() async {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Recherche de serveurs sur le réseau...';
      _discoveredServers = [];
    });

    try {
      final servers = await NetworkService.discoverServers();
      setState(() {
        _discoveredServers = servers;
        _isScanning = false;
        _statusMessage = servers.isEmpty 
            ? 'Aucun serveur trouvé sur le réseau'
            : '${servers.length} serveur(s) trouvé(s)';
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Erreur: $e';
      });
    }
  }

  Future<void> _setupAsServer({String? importDbPath}) async {
    if (_serverNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nom de serveur'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isSettingUp = true;
      _statusMessage = 'Configuration du serveur...';
    });

    try {
      // Handle database import if provided
      if (importDbPath != null) {
        final imported = await _importDatabase(importDbPath);
        if (!imported) {
          throw Exception('Échec de l\'importation');
        }
        setState(() => _statusMessage = 'Base de données importée avec succès!');
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Save server configuration
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_server', true);
      await prefs.setString('server_name', _serverNameController.text);
      await prefs.setBool('setup_complete', true);
      
      // Get local IP
      final ip = await NetworkService.getLocalIP();
      await prefs.setString('server_ip', ip);
      
      // Configure gRPC as server (use local database)
      GrpcClientConfig.setServerMode(true);
      GrpcClientConfig.setServerHost(ip);
      
      // Start broadcasting server presence
      await NetworkService.startServerBroadcast(_serverNameController.text);
      
      // Show success with database path
      final dbPath = await DatabasePath.getDbPath();
      final dbExists = await DatabasePath.databaseExists();
      final dbStatus = importDbPath != null 
          ? '✓ Base importée' 
          : (dbExists ? '✓ Base existante' : '✓ Nouvelle base créée');
      
      setState(() => _statusMessage = 'Serveur configuré!\nIP: $ip\n$dbStatus');
      
      // Wait a moment then complete
      await Future.delayed(const Duration(seconds: 2));
      
      // Show restart dialog if database was imported
      if (importDbPath != null && mounted) {
        await _showRestartDialog();
      } else {
        widget.onSetupComplete();
      }
      
    } catch (e) {
      setState(() {
        _isSettingUp = false;
        _statusMessage = 'Erreur: $e';
      });
    }
  }
  
  Future<void> _showRestartDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 28),
          SizedBox(width: 12),
          Text('Configuration terminée!'),
        ]),
        content: const Text(
          'La base de données a été importée avec succès.\n\n'
          'L\'application va maintenant redémarrer pour charger vos données.',
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              // Trigger app restart by calling onSetupComplete
              widget.onSetupComplete();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Continuer'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
          ),
        ],
      ),
    );
  }
  
  /// Import database from file - uses DatabasePath for correct location
  Future<bool> _importDatabase(String sourcePath) async {
    try {
      // Step 1: Show source info
      final sourceFile = File(sourcePath);
      final sourceSize = await sourceFile.length();
      final sourceSizeMB = (sourceSize / 1024 / 1024).toStringAsFixed(1);
      setState(() => _statusMessage = 'Fichier source: ${p.basename(sourcePath)}\nTaille: $sourceSizeMB MB');
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Step 2: Close any existing database connection
      setState(() => _statusMessage = 'Fermeture de la connexion actuelle...');
      if (AppDatabase.isInitialized) {
        await AppDatabase.instance.close();
        // Give time for the connection to fully close
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      // Step 3: Get destination path and show it
      final destPath = await DatabasePath.getDbPath();
      setState(() => _statusMessage = 'Destination: ${p.basename(destPath)}\nCopie en cours...');
      
      // Step 4: Import the database file
      final success = await DatabasePath.importDatabase(sourcePath);
      if (!success) {
        throw Exception('La copie du fichier a échoué');
      }
      
      // Step 5: Verify the file was copied
      final destFile = File(destPath);
      if (!await destFile.exists()) {
        throw Exception('Le fichier n\'existe pas après la copie');
      }
      final destSize = await destFile.length();
      if (destSize != sourceSize) {
        throw Exception('Taille incorrecte: $destSize vs $sourceSize octets');
      }
      
      setState(() => _statusMessage = 'Fichier copié avec succès!\nChargement de la base...');
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Step 6: Reinitialize the database with the imported file
      await AppDatabase.reinitialize();
      
      // Step 7: Verify we can read from it
      final db = AppDatabase.instance;
      final users = await db.select(db.users).get();
      final patients = await db.select(db.patients).get();
      
      if (users.isEmpty) {
        throw Exception('Aucun utilisateur trouvé dans la base importée');
      }
      
      final destSizeMB = (destSize / 1024 / 1024).toStringAsFixed(1);
      setState(() => _statusMessage = 
        '✓ Base importée avec succès!\n'
        '• ${users.length} utilisateur(s)\n'
        '• ${patients.length} patient(s)\n'
        '• Taille: $destSizeMB MB');
      
      await Future.delayed(const Duration(seconds: 1));
      return true;
      
    } catch (e) {
      print('Import error: $e');
      rethrow;
    }
  }
  
  /// Export/backup database to selected location
  static Future<String?> exportDatabase() async {
    try {
      final dbFile = await DatabasePath.getDbFile();
      if (!await dbFile.exists()) {
        return null;
      }
      
      // Let user pick save location
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Sauvegarder la base de données',
        fileName: 'medicore_backup_${DateTime.now().toString().split(' ')[0]}.db',
        type: FileType.custom,
        allowedExtensions: ['db'],
      );
      
      if (result != null) {
        await DatabasePath.exportDatabase(result);
        return result;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _connectToServer(ServerInfo server) async {
    setState(() {
      _isSettingUp = true;
      _statusMessage = 'Connexion à ${server.name}...';
    });

    try {
      // Test connection to server first
      setState(() => _statusMessage = 'Test de connexion...');
      final connected = await NetworkService.testConnection(server.ip, server.port);
      
      if (!connected) {
        setState(() {
          _isSettingUp = false;
          _statusMessage = 'Impossible de se connecter au serveur.\nVérifiez que le serveur est démarré.';
        });
        return;
      }
      
      // Save client configuration
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_server', false);
      await prefs.setString('server_ip', server.ip);
      await prefs.setString('server_name', server.name);
      await prefs.setBool('setup_complete', true);
      
      // Configure gRPC as client (connect to remote server)
      GrpcClientConfig.setServerMode(false);
      GrpcClientConfig.setServerHost(server.ip);
      
      setState(() => _statusMessage = 'Connecté à ${server.name}\nBase de données partagée');
      
      await Future.delayed(const Duration(seconds: 1));
      widget.onSetupComplete();
      
    } catch (e) {
      setState(() {
        _isSettingUp = false;
        _statusMessage = 'Erreur de connexion: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MediCoreColors.deepNavy,
      body: Center(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: MediCoreColors.paperWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Logo/Title
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [MediCoreColors.professionalBlue, Color(0xFF1565C0)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_hospital, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 24),
            Text('MediCore', style: MediCoreTypography.pageTitle.copyWith(fontSize: 32, color: MediCoreColors.deepNavy)),
            const SizedBox(height: 8),
            Text('Configuration Initiale', style: MediCoreTypography.body.copyWith(color: Colors.grey)),
            const SizedBox(height: 32),
            
            // Status message
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: MediCoreColors.canvasGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  if (_isScanning || _isSettingUp)
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    Icon(_discoveredServers.isNotEmpty ? Icons.check_circle : Icons.info, color: MediCoreColors.professionalBlue),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_statusMessage, style: const TextStyle(fontSize: 13))),
                ]),
              ),
            
            // Two options
            Row(children: [
              // SERVER OPTION
              Expanded(
                child: _OptionCard(
                  icon: Icons.dns,
                  title: 'SERVEUR',
                  subtitle: 'Premier ordinateur\n(Admin)',
                  color: const Color(0xFF2E7D32),
                  isSelected: false,
                  onTap: _isSettingUp ? null : () => _showServerDialog(),
                ),
              ),
              const SizedBox(width: 16),
              // CLIENT OPTION
              Expanded(
                child: _OptionCard(
                  icon: Icons.computer,
                  title: 'CLIENT',
                  subtitle: 'Se connecter au\nserveur existant',
                  color: const Color(0xFF1565C0),
                  isSelected: false,
                  onTap: _isSettingUp ? null : () => _showClientDialog(),
                ),
              ),
            ]),
            
            const SizedBox(height: 24),
            
            // Help text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.lightbulb, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Conseil: Choisissez "Serveur" sur l\'ordinateur principal (celui qui contiendra la base de données). '
                    'Les autres postes choisiront "Client" et se connecteront automatiquement.',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String? _uploadedDbPath;
  
  void _showServerDialog() {
    _uploadedDbPath = null;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF2E7D32).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.dns, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(width: 12),
            const Text('Configuration Serveur'),
          ]),
          content: SizedBox(
            width: 450,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: _serverNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du cabinet',
                  hintText: 'Ex: Cabinet Dr. Martin',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Database Options
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.storage, size: 20, color: Color(0xFF2E7D32)),
                    SizedBox(width: 8),
                    Text('Base de données', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ]),
                  const SizedBox(height: 12),
                  
                  // Upload database option
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['db', 'sqlite', 'sqlite3'],
                            dialogTitle: 'Sélectionner une base de données',
                          );
                          if (result != null && result.files.single.path != null) {
                            setDialogState(() {
                              _uploadedDbPath = result.files.single.path;
                            });
                          }
                        },
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Importer une base existante'),
                      ),
                    ),
                  ]),
                  
                  if (_uploadedDbPath != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(children: [
                        const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            p.basename(_uploadedDbPath!),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () => setDialogState(() => _uploadedDbPath = null),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ]),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text(
                      'Ou démarrer avec une nouvelle base vide',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                    ),
                  ],
                ]),
              ),
              
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline, color: Color(0xFF2E7D32), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FutureBuilder<String>(
                      future: NetworkService.getLocalIP(),
                      builder: (ctx, snap) => Text(
                        'Adresse IP: ${snap.data ?? "Détection..."}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32)),
                      ),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _setupAsServer(importDbPath: _uploadedDbPath);
              },
              icon: const Icon(Icons.check),
              label: Text(_uploadedDbPath != null ? 'Importer et créer' : 'Créer le serveur'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            ),
          ],
        ),
      ),
    );
  }

  void _showClientDialog() {
    _scanForServers();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF1565C0).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.computer, color: Color(0xFF1565C0)),
            ),
            const SizedBox(width: 12),
            const Text('Connexion Client'),
          ]),
          content: SizedBox(
            width: 400,
            height: 300,
            child: Column(children: [
              // Scan button
              ElevatedButton.icon(
                onPressed: _isScanning ? null : () async {
                  await _scanForServers();
                  setDialogState(() {});
                },
                icon: _isScanning 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.refresh),
                label: Text(_isScanning ? 'Recherche...' : 'Rechercher les serveurs'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
              ),
              const SizedBox(height: 16),
              // Server list
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _discoveredServers.isEmpty
                      ? Center(
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.wifi_find, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              _isScanning ? 'Recherche en cours...' : 'Aucun serveur trouvé\nVérifiez que le serveur est démarré',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ]),
                        )
                      : ListView.builder(
                          itemCount: _discoveredServers.length,
                          itemBuilder: (ctx, i) {
                            final server = _discoveredServers[i];
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFF2E7D32),
                                child: Icon(Icons.dns, color: Colors.white, size: 20),
                              ),
                              title: Text(server.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(server.ip),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                Navigator.pop(ctx);
                                _connectToServer(server);
                              },
                            );
                          },
                        ),
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? color.withOpacity(0.1) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 2 : 1),
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 40),
            ),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ]),
        ),
      ),
    );
  }
}
