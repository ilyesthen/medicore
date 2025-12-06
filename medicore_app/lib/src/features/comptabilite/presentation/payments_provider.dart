import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../data/payments_repository.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../users/presentation/users_provider.dart';
import '../../users/data/models/user_model.dart';

/// Provider for the payments repository
final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  final database = AppDatabase();
  return PaymentsRepository(database);
});

/// Provider for the selected date (for filtering payments)
/// Default: today's date
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Provider for the time filter
/// Options: 'all', 'morning', 'afternoon'
/// Default: 'all' (Journée Complète)
final timeFilterProvider = StateProvider<String>((ref) => 'all');

/// Provider for selected doctor (used by Nurse to view any doctor's payments)
/// null means show current user's payments (for Doctor/Assistant)
final selectedDoctorProvider = StateProvider<User?>((ref) => null);

/// Provider to get all users for nurse selection (doctors + assistants)
final allDoctorsProvider = FutureProvider<List<User>>((ref) async {
  final usersRepo = ref.watch(usersRepositoryProvider);
  final allUsers = await usersRepo.getAllUsers();
  // Return doctors and assistants (anyone who can have payments)
  return allUsers.where((u) => 
    isDoctor(u.role) || isAssistant(u.role)
  ).toList();
});

/// Helper to check user role type
bool isDoctor(String role) => 
    role.contains('Docteur') || role.contains('Dr') || role.contains('Médecin');
bool isAssistant(String role) => role.contains('Assistant');
bool isNurse(String role) => 
    role.contains('Infirmier') || role.contains('Infirmière');

/// Provider to watch payments for the current user, date, and time filter
/// This is the main data source for the Comptabilité dialog
final paymentsListProvider = StreamProvider.autoDispose<List<Payment>>((ref) {
  final repository = ref.watch(paymentsRepositoryProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  final timeFilter = ref.watch(timeFilterProvider);
  final authState = ref.watch(authStateProvider);
  final selectedDoctor = ref.watch(selectedDoctorProvider);
  
  final currentUser = authState.user;
  if (currentUser == null) {
    return Stream.value(<Payment>[]);
  }
  
  final userRole = currentUser.role;
  String targetUserName;
  
  if (isNurse(userRole)) {
    // Nurse can view any selected user's payments
    if (selectedDoctor == null) {
      return Stream.value(<Payment>[]);
    }
    targetUserName = selectedDoctor.name;
  } else if (isDoctor(userRole) || isAssistant(userRole)) {
    // Doctor and Assistant each view their OWN payments (linked to their name)
    targetUserName = currentUser.name;
  } else {
    return Stream.value(<Payment>[]);
  }
  
  return repository.watchPaymentsByUserAndDate(
    userName: targetUserName,
    date: selectedDate,
    timeFilter: timeFilter,
  );
});

/// Provider to get all assistants with their percentages
final allAssistantsProvider = FutureProvider<List<User>>((ref) async {
  final usersRepo = ref.watch(usersRepositoryProvider);
  final allUsers = await usersRepo.getAllUsers();
  // Return only assistants
  return allUsers.where((u) => u.role.contains('Assistant')).toList();
});

/// Provider to calculate summary statistics with role-specific data
final paymentsSummaryProvider = Provider.autoDispose<Map<String, dynamic>>((ref) {
  final paymentsAsync = ref.watch(paymentsListProvider);
  final authState = ref.watch(authStateProvider);
  final assistantsAsync = ref.watch(allAssistantsProvider);
  
  return paymentsAsync.when(
    data: (payments) {
      final repository = ref.read(paymentsRepositoryProvider);
      final totalAmount = repository.calculateTotalAmount(payments);
      final patientCount = repository.countUniquePatients(payments);
      final groupedByAct = repository.groupPaymentsByAct(payments);
      
      // Calculate assistant earnings based on their percentage
      final currentUser = authState.user;
      int myEarnings = 0;
      Map<String, int> assistantEarnings = {};
      
      if (currentUser != null && isAssistant(currentUser.role)) {
        // Calculate current assistant's earnings
        final percentage = currentUser.percentage ?? 0;
        myEarnings = (totalAmount * percentage / 100).round();
      }
      
      // For nurse view: calculate all assistants' earnings
      assistantsAsync.whenData((assistants) {
        for (final assistant in assistants) {
          final percentage = assistant.percentage ?? 0;
          assistantEarnings[assistant.name] = (totalAmount * percentage / 100).round();
        }
      });
      
      return {
        'totalAmount': totalAmount,
        'patientCount': patientCount,
        'groupedByAct': groupedByAct,
        'myEarnings': myEarnings,
        'assistantEarnings': assistantEarnings,
      };
    },
    loading: () => {
      'totalAmount': 0,
      'patientCount': 0,
      'groupedByAct': <String, Map<String, int>>{},
      'myEarnings': 0,
      'assistantEarnings': <String, int>{},
    },
    error: (_, __) => {
      'totalAmount': 0,
      'patientCount': 0,
      'groupedByAct': <String, Map<String, int>>{},
      'myEarnings': 0,
      'assistantEarnings': <String, int>{},
    },
  );
});
