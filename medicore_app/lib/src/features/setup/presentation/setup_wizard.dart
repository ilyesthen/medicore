import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/api/connection_manager.dart';

/// Setup Wizard - Connect to Go Server
/// Clean, fast, reliable server discovery and connection
class SetupWizard extends StatefulWidget {
  final VoidCallback onComplete;
  const SetupWizard({super.key, required this.onComplete});

  @override
  State<SetupWizard> createState() => _SetupWizardState();
}

class _SetupWizardState extends State<SetupWizard> with SingleTickerProviderStateMixin {
  // State
  String _status = 'Recherche du serveur...';
  bool _isScanning = false;
  bool _isConnecting = false;
  List<ServerInfo> _foundServers = [];
  final TextEditingController _ipController = TextEditingController();
  bool _showManualEntry = false;
  
  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Pulse animation for scanning
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Start scanning immediately
    _scanForServers();
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MediCoreColors.deepNavy,
      body: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Logo with pulse animation
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Transform.scale(
                scale: _isScanning ? _pulseAnimation.value : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1565C0),
                        const Color(0xFF0D47A1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1565C0).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.local_hospital, color: Colors.white, size: 48),
                ),
              ),
            ),
            const SizedBox(height: 28),
            
            // Title
            const Text(
              'MediCore',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: MediCoreColors.deepNavy,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Connexion au Serveur',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 28),
            
            // Status card
            _buildStatusCard(),
            const SizedBox(height: 20),
            
            // Server list
            _buildServerList(),
            const SizedBox(height: 16),
            
            // Action buttons
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isScanning || _isConnecting ? null : _scanForServers,
                  icon: Icon(_isScanning ? Icons.hourglass_top : Icons.refresh),
                  label: Text(_isScanning ? 'Recherche...' : 'Rechercher'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF1565C0)),
                    foregroundColor: const Color(0xFF1565C0),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _showManualEntry = !_showManualEntry),
                  icon: Icon(_showManualEntry ? Icons.close : Icons.edit),
                  label: Text(_showManualEntry ? 'Annuler' : 'IP Manuelle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF424242),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ]),
            
            // Manual IP entry
            if (_showManualEntry) ...[
              const SizedBox(height: 16),
              _buildManualEntry(),
            ],
            
            const SizedBox(height: 20),
            
            // Info box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF90CAF9)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline, color: Color(0xFF1565C0), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Assurez-vous que le serveur Go est démarré et les deux appareils sont sur le même réseau.',
                    style: TextStyle(fontSize: 12, color: Colors.blue[900], height: 1.4),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final isSuccess = _status.contains('✓') || _status.contains('✅') || _status.contains('Connecté');
    final isError = _status.toLowerCase().contains('erreur') || _status.toLowerCase().contains('impossible');
    
    Color bgColor, borderColor, textColor;
    IconData icon;
    
    if (isSuccess) {
      bgColor = const Color(0xFFE8F5E9);
      borderColor = const Color(0xFF4CAF50);
      textColor = const Color(0xFF2E7D32);
      icon = Icons.check_circle;
    } else if (isError) {
      bgColor = const Color(0xFFFFEBEE);
      borderColor = const Color(0xFFE53935);
      textColor = const Color(0xFFC62828);
      icon = Icons.error;
    } else {
      bgColor = const Color(0xFFE3F2FD);
      borderColor = const Color(0xFF2196F3);
      textColor = const Color(0xFF1565C0);
      icon = Icons.info;
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(children: [
        if (_isScanning || _isConnecting)
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        else
          Icon(icon, color: borderColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _status,
            style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w500),
          ),
        ),
      ]),
    );
  }

  Widget _buildServerList() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: _foundServers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isScanning ? Icons.wifi_find : Icons.search_off,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isScanning ? 'Recherche en cours...' : 'Aucun serveur trouvé',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: _foundServers.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final server = _foundServers[i];
                return Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.dns, color: Colors.white, size: 22),
                    ),
                    title: Text(
                      server.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      server.ip,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onTap: _isConnecting ? null : () => _connectToServer(server),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildManualEntry() {
    return Row(children: [
      Expanded(
        child: TextField(
          controller: _ipController,
          decoration: InputDecoration(
            hintText: '192.168.1.100',
            prefixIcon: const Icon(Icons.computer),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          keyboardType: TextInputType.number,
          onSubmitted: (_) => _connectManual(),
        ),
      ),
      const SizedBox(width: 12),
      ElevatedButton(
        onPressed: _isConnecting ? null : _connectManual,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _isConnecting
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.arrow_forward),
      ),
    ]);
  }

  Future<void> _scanForServers() async {
    if (_isScanning) return;
    
    setState(() {
      _isScanning = true;
      _status = 'Recherche sur le réseau...';
      _foundServers = [];
    });

    try {
      final servers = await ConnectionManager.instance.discoverServers(
        timeout: const Duration(seconds: 10),
        onFound: (server) {
          if (mounted) {
            setState(() {
              _foundServers = [..._foundServers, server];
              _status = '${_foundServers.length} serveur(s) trouvé(s)';
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _foundServers = servers;
          _isScanning = false;
          _status = servers.isEmpty 
              ? 'Aucun serveur trouvé. Vérifiez que le serveur est démarré.'
              : '${servers.length} serveur(s) trouvé(s) - Cliquez pour connecter';
        });
        
        // Auto-connect if only one server found
        if (servers.length == 1) {
          _connectToServer(servers.first);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _status = 'Erreur de recherche: $e';
        });
      }
    }
  }

  Future<void> _connectManual() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      setState(() => _status = 'Erreur: Entrez une adresse IP');
      return;
    }
    await _connectToServer(ServerInfo(ip: ip, name: 'MediCore Server'));
  }

  Future<void> _connectToServer(ServerInfo server) async {
    if (_isConnecting) return;
    
    setState(() {
      _isConnecting = true;
      _status = 'Connexion à ${server.name}...';
    });

    try {
      print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔗 CONNECTING TO SERVER: ${server.ip}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      final success = await ConnectionManager.instance.connect(server.ip, server.name);
      
      if (success) {
        setState(() => _status = '✓ Connecté à ${server.name}');
        
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('✅ CONNECTED TO SERVER');
        print('📡 Server: ${server.name}');
        print('🔗 IP: ${server.ip}:50052');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) widget.onComplete();
      } else {
        if (mounted) {
          setState(() {
            _isConnecting = false;
            _status = 'Erreur: Impossible de se connecter.\n\n'
                'Vérifiez que:\n'
                '• Le serveur Go est démarré\n'
                '• Les deux appareils sont sur le même réseau';
          });
        }
      }
    } catch (e) {
      print('❌ Connection error: $e');
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _status = 'Erreur: $e';
        });
      }
    }
  }
}
