/// AI Safety Validator - Catches dangerous medical commands
/// Runs BEFORE actions are executed to prevent harm
class AISafetyValidator {
  
  /// Known dangerous medication dosages (simplified example)
  static const Map<String, SafeDosageRange> _medicationLimits = {
    // Eye drops - usually in % or mg/ml, NOT mg
    'timolol': SafeDosageRange(maxDose: 0.5, unit: '%', warnAbove: 0.5),
    'latanoprost': SafeDosageRange(maxDose: 0.005, unit: '%', warnAbove: 0.005),
    'pilocarpine': SafeDosageRange(maxDose: 4, unit: '%', warnAbove: 2),
    'atropine': SafeDosageRange(maxDose: 1, unit: '%', warnAbove: 0.5),
    'dexamethasone': SafeDosageRange(maxDose: 0.1, unit: '%', warnAbove: 0.1),
    
    // Oral medications
    'aciclovir': SafeDosageRange(maxDose: 800, unit: 'mg', warnAbove: 400),
    'valaciclovir': SafeDosageRange(maxDose: 1000, unit: 'mg', warnAbove: 500),
    'prednisone': SafeDosageRange(maxDose: 80, unit: 'mg', warnAbove: 40),
    'acetazolamide': SafeDosageRange(maxDose: 1000, unit: 'mg', warnAbove: 500),
  };
  
  /// Drug interactions to flag
  static const Map<String, List<String>> _drugInteractions = {
    'timolol': ['propranolol', 'metoprolol', 'atenolol', 'bisoprolol'], // Beta blockers
    'acetazolamide': ['aspirin', 'lithium', 'methotrexate'],
    'latanoprost': ['bimatoprost', 'travoprost'], // Don't combine prostaglandins
    'pilocarpine': ['atropine', 'tropicamide'], // Antagonists
  };
  
  /// Conditions that contraindicate certain drugs
  static const Map<String, List<String>> _contraindications = {
    'timolol': ['asthma', 'bradycardia', 'heart block', 'copd'],
    'pilocarpine': ['acute iritis', 'uveitis'],
    'atropine': ['glaucoma', 'angle closure'],
    'steroids': ['corneal ulcer', 'herpes keratitis', 'fungal infection'],
    'dexamethasone': ['corneal ulcer', 'herpes keratitis', 'fungal infection'],
  };
  
  /// Validate a prescription before execution
  /// Returns list of safety warnings (empty = safe)
  List<SafetyWarning> validatePrescription({
    required List<Map<String, dynamic>> medications,
    List<String>? patientConditions,
    List<String>? currentMedications,
    List<String>? allergies,
  }) {
    final warnings = <SafetyWarning>[];
    
    for (final med in medications) {
      final name = (med['name'] as String? ?? '').toLowerCase();
      final doseStr = med['dose'] as String? ?? '';
      
      // 1. Check dosage limits
      final dosageWarning = _checkDosage(name, doseStr);
      if (dosageWarning != null) {
        warnings.add(dosageWarning);
      }
      
      // 2. Check drug interactions
      if (currentMedications != null) {
        final interactionWarning = _checkInteractions(name, currentMedications);
        if (interactionWarning != null) {
          warnings.add(interactionWarning);
        }
      }
      
      // 3. Check contraindications
      if (patientConditions != null) {
        final contraindicationWarning = _checkContraindications(name, patientConditions);
        if (contraindicationWarning != null) {
          warnings.add(contraindicationWarning);
        }
      }
      
      // 4. Check allergies
      if (allergies != null && allergies.any((a) => name.contains(a.toLowerCase()))) {
        warnings.add(SafetyWarning(
          level: SafetyLevel.critical,
          message: '🚨 ALLERGIE CONNUE: $name',
          suggestion: 'Vérifier le dossier allergies',
        ));
      }
    }
    
    return warnings;
  }
  
  /// Check if dosage is within safe limits
  SafetyWarning? _checkDosage(String drugName, String doseStr) {
    // Find the drug in our limits
    String? matchedDrug;
    for (final drug in _medicationLimits.keys) {
      if (drugName.contains(drug)) {
        matchedDrug = drug;
        break;
      }
    }
    
    if (matchedDrug == null) return null;
    
    final limits = _medicationLimits[matchedDrug]!;
    
    // Parse the dose
    final numMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(%|mg|ml)?').firstMatch(doseStr);
    if (numMatch == null) return null;
    
    final doseValue = double.tryParse(numMatch.group(1) ?? '0') ?? 0;
    final doseUnit = numMatch.group(2)?.toLowerCase() ?? '';
    
    // Check for unit mismatch (e.g., "500mg" for eye drops that should be in %)
    if (limits.unit == '%' && doseUnit == 'mg' && doseValue > 10) {
      return SafetyWarning(
        level: SafetyLevel.critical,
        message: '🚨 DOSAGE SUSPECT: $drugName $doseStr',
        suggestion: '${matchedDrug.toUpperCase()} est habituellement dosé en ${limits.unit}, pas en mg. Dose max: ${limits.maxDose}${limits.unit}',
      );
    }
    
    // Check if dose exceeds maximum
    if (doseValue > limits.maxDose) {
      return SafetyWarning(
        level: SafetyLevel.critical,
        message: '⚠️ SURDOSAGE: $drugName $doseStr dépasse le max (${limits.maxDose}${limits.unit})',
        suggestion: 'Dose recommandée: ≤${limits.maxDose}${limits.unit}',
      );
    }
    
    // Warn if above typical dose
    if (doseValue > limits.warnAbove) {
      return SafetyWarning(
        level: SafetyLevel.warning,
        message: '⚠️ Dose élevée: $drugName $doseStr (habituel: ≤${limits.warnAbove}${limits.unit})',
        suggestion: 'Confirmer si dose intentionnelle',
      );
    }
    
    return null;
  }
  
  /// Check for drug interactions
  SafetyWarning? _checkInteractions(String drugName, List<String> currentMeds) {
    for (final entry in _drugInteractions.entries) {
      if (drugName.contains(entry.key)) {
        for (final interactingDrug in entry.value) {
          if (currentMeds.any((m) => m.toLowerCase().contains(interactingDrug))) {
            return SafetyWarning(
              level: SafetyLevel.warning,
              message: '⚠️ INTERACTION: $drugName + $interactingDrug',
              suggestion: 'Vérifier compatibilité ou ajuster doses',
            );
          }
        }
      }
    }
    return null;
  }
  
  /// Check for contraindications
  SafetyWarning? _checkContraindications(String drugName, List<String> conditions) {
    for (final entry in _contraindications.entries) {
      if (drugName.contains(entry.key)) {
        for (final contraCondition in entry.value) {
          if (conditions.any((c) => c.toLowerCase().contains(contraCondition))) {
            return SafetyWarning(
              level: SafetyLevel.critical,
              message: '🚨 CONTRE-INDICATION: $drugName + $contraCondition',
              suggestion: 'Choisir un traitement alternatif',
            );
          }
        }
      }
    }
    return null;
  }
  
  /// Validate voice input for ambiguity before sending to AI
  List<SafetyWarning> validateVoiceInput(String input) {
    final warnings = <SafetyWarning>[];
    final lower = input.toLowerCase();
    
    // Check for vague dosages
    if (lower.contains('the usual') || lower.contains('comme d\'habitude') || lower.contains('le même')) {
      warnings.add(SafetyWarning(
        level: SafetyLevel.info,
        message: 'ℹ️ Dosage non spécifié',
        suggestion: 'Préciser la dose exacte',
      ));
    }
    
    // Check for potentially dangerous phrases
    if (lower.contains('all') && lower.contains('give') && !lower.contains('colly')) {
      warnings.add(SafetyWarning(
        level: SafetyLevel.info,
        message: 'ℹ️ Commande large détectée',
        suggestion: 'Confirmer les médicaments spécifiques',
      ));
    }
    
    return warnings;
  }
}

/// Safe dosage range for a medication
class SafeDosageRange {
  final double maxDose;
  final String unit;
  final double warnAbove;
  
  const SafeDosageRange({
    required this.maxDose,
    required this.unit,
    required this.warnAbove,
  });
}

/// Safety warning levels
enum SafetyLevel {
  info,     // Just informational
  warning,  // Needs confirmation
  critical, // STOP - do not proceed without override
}

/// A safety warning
class SafetyWarning {
  final SafetyLevel level;
  final String message;
  final String suggestion;
  
  SafetyWarning({
    required this.level,
    required this.message,
    required this.suggestion,
  });
  
  bool get isCritical => level == SafetyLevel.critical;
  bool get isWarning => level == SafetyLevel.warning;
  
  @override
  String toString() => '$message\n💡 $suggestion';
}
