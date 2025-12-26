import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/api/grpc_client.dart';
import 'package:http/http.dart' as http;

/// Professional Setup Wizard - Client-Only Mode
/// Connects to centralized MediCore server
class SetupWizardSimplified extends StatefulWidget {
  final VoidCallback onComplete;
  const SetupWizardSimplified({super.key, required this.onComplete});

  @override
  State<SetupWizardSimplified> createState() => _SetupWizardSimplifiedState();
}

class _SetupWizardSimplifiedState extends State<SetupWizardSimplified> {
  int _currentStep = 0;
  String _status = '';
  bool _isWorking = false;
  
  // Server discovery
  List<_ServerInfo> _foundServers = [];
  bool _scanning = false;
  
  // Manual server entry
  final _serverIpController = TextEditingController(text: '192.168.1.5');
  String? _selectedServerIp;
  
  // Connection test
  bool _connectionTested = false;
  bool _connectionSuccess = false;
  
  @override
  void initState() {
    super.initState();
    _scanForServers();
  }

  @override
  void dispose() {
    _serverIpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MediCoreColors.deepNavy,
      body: Center(
        child: Container(
          width: 650,
          constraints: const BoxConstraints(maxHeight: 700),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              Expanded(
                child: _buildCurrentStep(),
              ),
              const SizedBox(height: 24),
              _buildNavigationButtons(),
              if (_status.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildStatusMessage(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.cloud_outlined, color: Colors.white, size: 56),
        ),
        const SizedBox(height: 16),
        const Text(
          'MediCore Setup',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: MediCoreColors.deepNavy,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Professional Client-Server Architecture',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        _buildStepIndicator(),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepDot(0, 'Server'),
        _buildStepLine(0),
        _buildStepDot(1, 'Test'),
        _buildStepLine(1),
        _buildStepDot(2, 'Complete'),
      ],
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1565C0) : Colors.grey.shade300,
            shape: BoxShape.circle,
            border: isCurrent
                ? Border.all(color: const Color(0xFF1565C0), width: 3)
                : null,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? const Color(0xFF1565C0) : Colors.grey.shade600,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = _currentStep > step;
    return Container(
      width: 60,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isActive ? const Color(0xFF1565C0) : Colors.grey.shade300,
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildServerSelectionStep();
      case 1:
        return _buildConnectionTestStep();
      case 2:
        return _buildCompleteStep();
      default:
        return Container();
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // STEP 1: SERVER SELECTION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildServerSelectionStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 1: Select Server',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: MediCoreColors.deepNavy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a discovered server or enter manually',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          
          // Auto-discovered servers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Discovered Servers',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              if (_scanning)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                TextButton.icon(
                  onPressed: _scanForServers,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (_foundServers.isEmpty && !_scanning)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'No servers found. Enter server IP manually below.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          
          if (_foundServers.isNotEmpty)
            ...List.generate(_foundServers.length, (index) {
              final server = _foundServers[index];
              final isSelected = _selectedServerIp == server.ip;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedServerIp = server.ip;
                      _serverIpController.text = server.ip;
                      _connectionTested = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1565C0).withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1565C0)
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.router,
                            color: Colors.green.shade700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                server.computerName ?? 'MediCore Server',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                server.ip,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF1565C0),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          
          // Manual server entry
          const Text(
            'Or Enter Manually',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _serverIpController,
            decoration: InputDecoration(
              labelText: 'Server IP Address',
              hintText: 'e.g., 192.168.1.100',
              prefixIcon: const Icon(Icons.dns),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: (value) {
              setState(() {
                _selectedServerIp = value;
                _connectionTested = false;
              });
            },
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // STEP 2: CONNECTION TEST
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildConnectionTestStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 2: Test Connection',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: MediCoreColors.deepNavy,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Verifying connection to MediCore server',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 32),
        
        Center(
          child: Column(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _connectionSuccess
                      ? Colors.green.shade50
                      : _isWorking
                          ? Colors.blue.shade50
                          : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _isWorking
                      ? const CircularProgressIndicator()
                      : Icon(
                          _connectionSuccess
                              ? Icons.check_circle
                              : Icons.cloud_off,
                          size: 60,
                          color: _connectionSuccess
                              ? Colors.green.shade700
                              : Colors.grey.shade400,
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _connectionSuccess
                    ? '✅ Connection Successful!'
                    : _isWorking
                        ? 'Testing connection...'
                        : 'Ready to test',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _connectionSuccess
                      ? Colors.green.shade700
                      : MediCoreColors.deepNavy,
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedServerIp != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.dns, size: 16),
                      const SizedBox(width: 8),
                      Text(_selectedServerIp!),
                    ],
                  ),
                ),
            ],
          ),
        ),
        
        const Spacer(),
        
        if (!_connectionSuccess && !_isWorking)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _testConnection,
              icon: const Icon(Icons.wifi_find),
              label: const Text('Test Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // STEP 3: COMPLETE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildCompleteStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            size: 60,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Setup Complete!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: MediCoreColors.deepNavy,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Connected to MediCore server',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.dns, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Server Address',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _selectedServerIp ?? '',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _completeSetup,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Launch MediCore'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // NAVIGATION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0 && _currentStep < 2)
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _currentStep--;
                  _status = '';
                });
              },
              child: const Text('Back'),
            ),
          ),
        if (_currentStep > 0 && _currentStep < 2) const SizedBox(width: 16),
        if (_currentStep < 2)
          Expanded(
            child: ElevatedButton(
              onPressed: _canProceed() ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
              child: const Text('Next'),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusMessage() {
    final isError = _status.startsWith('❌') || _status.startsWith('⚠️');
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? Colors.red.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError ? Colors.red.shade200 : Colors.blue.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            color: isError ? Colors.red.shade700 : Colors.blue.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _status,
              style: TextStyle(
                fontSize: 13,
                color: isError ? Colors.red.shade900 : Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // LOGIC
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedServerIp != null && _selectedServerIp!.isNotEmpty;
      case 1:
        return _connectionSuccess;
      default:
        return true;
    }
  }

  void _nextStep() {
    setState(() {
      _currentStep++;
      _status = '';
    });
    
    if (_currentStep == 1) {
      _testConnection();
    }
  }

  Future<void> _scanForServers() async {
    setState(() {
      _scanning = true;
      _foundServers = [];
      _status = '🔍 Scanning network...';
    });

    try {
      // UDP broadcast discovery
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 45677);
      socket.broadcastEnabled = true;

      final completer = Completer<void>();
      Timer(const Duration(seconds: 3), () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            try {
              final data = utf8.decode(datagram.data);
              final json = jsonDecode(data) as Map<String, dynamic>;
              
              if (json['type'] == 'MEDICORE_SERVER' ||
                  json['type'] == 'medicore') {
                final server = _ServerInfo(
                  ip: json['ip'] as String? ?? datagram.address.address,
                  computerName: json['computerName'] as String?,
                  port: json['port'] as int? ?? 50051,
                );

                setState(() {
                  if (!_foundServers.any((s) => s.ip == server.ip)) {
                    _foundServers.add(server);
                  }
                });
              }
            } catch (e) {
              // Ignore malformed responses
            }
          }
        }
      });

      // Send discovery request
      final request = utf8.encode('MEDICORE_DISCOVER');
      socket.send(request, InternetAddress('255.255.255.255'), 45677);

      await completer.future;
      socket.close();

      setState(() {
        _scanning = false;
        _status = _foundServers.isEmpty
            ? '⚠️ No servers found on network'
            : '✅ Found ${_foundServers.length} server(s)';
      });
    } catch (e) {
      setState(() {
        _scanning = false;
        _status = '❌ Scan failed: $e';
      });
    }
  }

  Future<void> _testConnection() async {
    if (_selectedServerIp == null || _selectedServerIp!.isEmpty) {
      setState(() {
        _status = '❌ Please enter a server IP address';
      });
      return;
    }

    setState(() {
      _isWorking = true;
      _status = 'Testing connection to $_selectedServerIp...';
      _connectionSuccess = false;
    });

    try {
      // Test health endpoint
      final url = Uri.parse('http://$_selectedServerIp:50052/api/health');
      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        setState(() {
          _connectionSuccess = true;
          _status = '✅ Connection successful!';
          _isWorking = false;
        });
      } else {
        setState(() {
          _connectionSuccess = false;
          _status = '❌ Server responded with status ${response.statusCode}';
          _isWorking = false;
        });
      }
    } catch (e) {
      setState(() {
        _connectionSuccess = false;
        _status = '❌ Connection failed: Cannot reach server';
        _isWorking = false;
      });
    }
  }

  Future<void> _completeSetup() async {
    setState(() {
      _isWorking = true;
      _status = 'Saving configuration...';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // CRITICAL: Save as CLIENT mode (NOT admin/server mode)
      await prefs.setBool('is_server', false);  // MUST be false for REST API client
      await prefs.setString('mode', 'client');
      await prefs.setString('server_ip', _selectedServerIp!);
      await prefs.setInt('server_port', 50052);
      await prefs.setString('server_url', 'http://$_selectedServerIp:50052');
      await prefs.setBool('setup_complete', true);
      await prefs.setString('app_version', '5.0.0');
      
      print('✅ Saved configuration:');
      print('   - Mode: CLIENT (is_server=false)');
      print('   - Server IP: $_selectedServerIp');
      print('   - Server URL: http://$_selectedServerIp:50052');

      // Configure GrpcClient as CLIENT
      GrpcClientConfig.setServerHost(_selectedServerIp!);
      GrpcClientConfig.setServerMode(false);  // CLIENT mode

      setState(() {
        _status = '✅ Configuration saved as CLIENT mode!';
        _isWorking = false;
      });

      // Complete setup
      await Future.delayed(const Duration(milliseconds: 800));
      widget.onComplete();
    } catch (e) {
      setState(() {
        _status = '❌ Failed to save configuration: $e';
        _isWorking = false;
      });
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SERVER INFO MODEL
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _ServerInfo {
  final String ip;
  final String? computerName;
  final int port;

  _ServerInfo({
    required this.ip,
    this.computerName,
    required this.port,
  });
}
