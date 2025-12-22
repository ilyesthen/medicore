import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../patients/data/xml_import_service.dart';

/// Dialog for importing patients from XML
class ImportPatientsDialog extends ConsumerStatefulWidget {
  const ImportPatientsDialog({super.key});

  @override
  ConsumerState<ImportPatientsDialog> createState() => _ImportPatientsDialogState();
}

class _ImportPatientsDialogState extends ConsumerState<ImportPatientsDialog> {
  bool _isImporting = false;
  String? _result;
  int _successCount = 0;
  int _errorCount = 0;
  List<String> _errors = [];

  Future<void> _startImport() async {
    setState(() {
      _isImporting = true;
      _result = null;
      _errors = [];
    });

    try {
      final repository = PatientsRepository();
      final importService = XmlImportService(repository);
      
      final result = await importService.importFromXml('/Applications/eye/patients.xml');
      
      setState(() {
        _isImporting = false;
        _successCount = result.successCount;
        _errorCount = result.errorCount;
        _errors = result.errors;
        
        if (result.isSuccess) {
          _result = 'success';
        } else if (result.successCount > 0) {
          _result = 'partial';
        } else {
          _result = 'error';
        }
      });
    } catch (e) {
      setState(() {
        _isImporting = false;
        _result = 'error';
        _errorCount = 1;
        _errors = ['Erreur fatale: $e'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: MediCoreColors.paperWhite,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: MediCoreColors.deepNavy,
                border: Border(
                  bottom: BorderSide(
                    color: MediCoreColors.steelOutline,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.upload_file,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'IMPORTATION PATIENTS',
                    style: MediCoreTypography.pageTitle.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_result == null && !_isImporting) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: MediCoreColors.professionalBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: MediCoreColors.professionalBlue,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: MediCoreColors.professionalBlue,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Cette opération va importer tous les patients depuis le fichier XML.',
                              style: MediCoreTypography.body,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Fichier: /Applications/eye/patients.xml',
                              style: MediCoreTypography.label.copyWith(
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Le fichier sera supprimé après l\'import.',
                              style: MediCoreTypography.label.copyWith(
                                color: MediCoreColors.criticalRed,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_isImporting) ...[
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 20),
                            Text('Importation en cours...'),
                            SizedBox(height: 8),
                            Text(
                              'Cela peut prendre quelques minutes',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_result == 'success') ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: MediCoreColors.healthyGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: MediCoreColors.healthyGreen,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: MediCoreColors.healthyGreen,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Import réussi !',
                              style: MediCoreTypography.pageTitle.copyWith(
                                color: MediCoreColors.healthyGreen,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '$_successCount patients importés',
                              style: MediCoreTypography.sectionHeader,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Le fichier XML a été supprimé.',
                              style: MediCoreTypography.label.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_result == 'partial' || _result == 'error') ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: (_result == 'error' 
                              ? MediCoreColors.criticalRed 
                              : Colors.orange).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _result == 'error' 
                                ? MediCoreColors.criticalRed 
                                : Colors.orange,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _result == 'error' 
                                  ? Icons.error 
                                  : Icons.warning,
                              color: _result == 'error' 
                                  ? MediCoreColors.criticalRed 
                                  : Colors.orange,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _result == 'error' 
                                  ? 'Erreur d\'import' 
                                  : 'Import partiel',
                              style: MediCoreTypography.pageTitle.copyWith(
                                color: _result == 'error' 
                                    ? MediCoreColors.criticalRed 
                                    : Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_successCount > 0)
                              Text(
                                '$_successCount patients importés',
                                style: MediCoreTypography.body,
                              ),
                            if (_errorCount > 0)
                              Text(
                                '$_errorCount erreurs',
                                style: MediCoreTypography.body.copyWith(
                                  color: MediCoreColors.criticalRed,
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      if (_errors.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Erreurs détaillées:',
                          style: MediCoreTypography.sectionHeader,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _errors.map((error) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '• $error',
                                    style: MediCoreTypography.label.copyWith(
                                      color: Colors.red[800],
                                      fontSize: 11,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: MediCoreColors.steelOutline,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_result != null || !_isImporting)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        _result != null ? 'FERMER' : 'ANNULER',
                        style: MediCoreTypography.button.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  if (_result == null && !_isImporting) ...[
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _startImport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MediCoreColors.professionalBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: Text(
                        'DÉMARRER L\'IMPORT',
                        style: MediCoreTypography.button,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
