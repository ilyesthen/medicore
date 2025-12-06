import 'package:medicore_app/src/core/database/app_database.dart';

/// Check how many patients are in the database
Future<void> main() async {
  print('🔍 Checking patient database...\n');
  
  final db = AppDatabase();
  
  try {
    final patients = await db.select(db.patients).get();
    
    print('✅ Found ${patients.length} patients in database');
    
    if (patients.isNotEmpty) {
      print('\n📊 Sample patients:');
      for (int i = 0; i < patients.length.take(5).length; i++) {
        final p = patients[i];
        print('   ${p.code}. ${p.firstName} ${p.lastName} - Created: ${p.createdAt}');
      }
      
      print('\n📈 Stats:');
      print('   First patient code: ${patients.first.code}');
      print('   Last patient code: ${patients.last.code}');
    } else {
      print('\n⚠️  Database is empty - no patients found!');
    }
    
    await db.close();
  } catch (e) {
    print('❌ Error: $e');
  }
}
