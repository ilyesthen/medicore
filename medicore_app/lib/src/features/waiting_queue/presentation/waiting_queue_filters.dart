import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/types/proto_types.dart';

/// Filter state for waiting queue dialogs
class WaitingQueueFilterState {
  final String nameFilter;
  final String? motifFilter;
  final bool checkedFirst;
  final bool oldestFirst; // true = oldest first, false = newest first

  const WaitingQueueFilterState({
    this.nameFilter = '',
    this.motifFilter,
    this.checkedFirst = false,
    this.oldestFirst = true,
  });

  WaitingQueueFilterState copyWith({
    String? nameFilter,
    String? motifFilter,
    bool? clearMotifFilter,
    bool? checkedFirst,
    bool? oldestFirst,
  }) {
    return WaitingQueueFilterState(
      nameFilter: nameFilter ?? this.nameFilter,
      motifFilter: clearMotifFilter == true ? null : (motifFilter ?? this.motifFilter),
      checkedFirst: checkedFirst ?? this.checkedFirst,
      oldestFirst: oldestFirst ?? this.oldestFirst,
    );
  }
}

/// Provider for waiting queue filter state (regular queue)
final waitingQueueFilterProvider = StateProvider.autoDispose<WaitingQueueFilterState>((ref) {
  return const WaitingQueueFilterState();
});

/// Provider for urgent queue filter state
final urgentQueueFilterProvider = StateProvider.autoDispose<WaitingQueueFilterState>((ref) {
  return const WaitingQueueFilterState();
});

/// Provider for dilatation queue filter state
final dilatationQueueFilterProvider = StateProvider.autoDispose<WaitingQueueFilterState>((ref) {
  return const WaitingQueueFilterState();
});

/// Apply filters to a list of waiting patients
List<WaitingPatient> applyWaitingQueueFilters(
  List<WaitingPatient> patients,
  WaitingQueueFilterState filters,
) {
  var filtered = patients.toList();

  // Filter by name (starts with)
  if (filters.nameFilter.isNotEmpty) {
    final query = filters.nameFilter.toLowerCase();
    filtered = filtered.where((p) {
      final fullName = '${p.patientLastName} ${p.patientFirstName}'.toLowerCase();
      final reverseName = '${p.patientFirstName} ${p.patientLastName}'.toLowerCase();
      return fullName.startsWith(query) || 
             reverseName.startsWith(query) ||
             p.patientLastName.toLowerCase().startsWith(query) ||
             p.patientFirstName.toLowerCase().startsWith(query);
    }).toList();
  }

  // Filter by motif
  if (filters.motifFilter != null && filters.motifFilter!.isNotEmpty) {
    filtered = filtered.where((p) => p.motif == filters.motifFilter).toList();
  }

  // Sort by checked first
  if (filters.checkedFirst) {
    filtered.sort((a, b) {
      if (a.isChecked && !b.isChecked) return -1;
      if (!a.isChecked && b.isChecked) return 1;
      // Secondary sort by time
      return filters.oldestFirst 
          ? a.sentAt.compareTo(b.sentAt)
          : b.sentAt.compareTo(a.sentAt);
    });
  } else {
    // Sort by time only
    filtered.sort((a, b) => filters.oldestFirst 
        ? a.sentAt.compareTo(b.sentAt)
        : b.sentAt.compareTo(a.sentAt));
  }

  return filtered;
}

/// Get unique motifs from a list of patients
Set<String> getUniqueMotifs(List<WaitingPatient> patients) {
  return patients.map((p) => p.motif).toSet();
}

/// Filter control bar widget for waiting queue dialogs
class WaitingQueueFilterBar extends ConsumerWidget {
  final Color accentColor;
  final AutoDisposeStateProvider<WaitingQueueFilterState> filterProvider;
  final List<WaitingPatient> patients;
  final String motifLabel;

  const WaitingQueueFilterBar({
    super.key,
    required this.accentColor,
    required this.filterProvider,
    required this.patients,
    this.motifLabel = 'MOTIF',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(filterProvider);
    final uniqueMotifs = getUniqueMotifs(patients).toList()..sort();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: MediCoreColors.canvasGrey,
        border: Border(
          bottom: BorderSide(color: accentColor.withOpacity(0.3), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Name search
          SizedBox(
            width: 200,
            height: 36,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher par nom...',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, size: 18, color: accentColor),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: accentColor.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: accentColor.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: accentColor, width: 2),
                ),
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (value) {
                ref.read(filterProvider.notifier).state = filters.copyWith(nameFilter: value);
              },
            ),
          ),
          const SizedBox(width: 12),

          // Motif dropdown filter
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: accentColor.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: filters.motifFilter,
                hint: Text('Tous les $motifLabel', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                icon: Icon(Icons.arrow_drop_down, color: accentColor),
                style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.w500),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Tous les $motifLabel', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                  ),
                  ...uniqueMotifs.map((motif) => DropdownMenuItem<String?>(
                    value: motif,
                    child: Text(
                      motif.length > 25 ? '${motif.substring(0, 25)}...' : motif,
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  )),
                ],
                onChanged: (value) {
                  ref.read(filterProvider.notifier).state = filters.copyWith(
                    motifFilter: value,
                    clearMotifFilter: value == null,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Checked first toggle
          _FilterToggleButton(
            icon: Icons.star,
            label: '★ En premier',
            isActive: filters.checkedFirst,
            activeColor: Colors.amber,
            onTap: () {
              ref.read(filterProvider.notifier).state = filters.copyWith(
                checkedFirst: !filters.checkedFirst,
              );
            },
          ),
          const SizedBox(width: 8),

          // Sort order toggle
          _FilterToggleButton(
            icon: filters.oldestFirst ? Icons.arrow_upward : Icons.arrow_downward,
            label: filters.oldestFirst ? 'Ancien → Récent' : 'Récent → Ancien',
            isActive: true,
            activeColor: accentColor,
            onTap: () {
              ref.read(filterProvider.notifier).state = filters.copyWith(
                oldestFirst: !filters.oldestFirst,
              );
            },
          ),

          const Spacer(),

          // Clear filters button
          if (filters.nameFilter.isNotEmpty || filters.motifFilter != null || filters.checkedFirst || !filters.oldestFirst)
            TextButton.icon(
              onPressed: () {
                ref.read(filterProvider.notifier).state = const WaitingQueueFilterState();
              },
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Effacer filtres', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _FilterToggleButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isActive ? activeColor : Colors.grey[300]!,
            width: isActive ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? activeColor : Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? activeColor : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
