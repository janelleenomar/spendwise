// lib/models/expense.dart
import 'package:hive/hive.dart';

// The 'part' directive links this file to a generated file we will create next.
part 'expense.g.dart';

// ── Expense Category Enum ──────────────────────────────────────────────────
// @HiveType registers this enum. typeId MUST be unique across the project.
@HiveType(typeId: 0)
enum ExpenseCategory {
  @HiveField(0) food,          
  @HiveField(1) transport,     
  @HiveField(2) shopping,      
  @HiveField(3) utilities,     
  @HiveField(4) entertainment, 
  @HiveField(5) other,         
}

// ── Expense Class ──────────────────────────────────────────────────────────
// typeId: 1 is unique for this class.
// Extending HiveObject gives us access to helpful shortcuts later.
@HiveType(typeId: 1)
class Expense extends HiveObject {
  
  // Each field must have a unique ID within this class (0, 1, 2, 3...)
  @HiveField(0)
  late String title; 

  @HiveField(1)
  late double amount; 

  @HiveField(2)
  late ExpenseCategory category; 

  @HiveField(3)
  late DateTime date; 

  // The constructor for creating new Expense objects
  Expense({
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  // A helper to turn the enum into a readable String for our UI.
  // Notice this does NOT have a @HiveField because it isn't saved to the database.
  String get categoryName {
    switch (category) {
      case ExpenseCategory.food:          return 'Food';
      case ExpenseCategory.transport:     return 'Transport';
      case ExpenseCategory.shopping:      return 'Shopping';
      case ExpenseCategory.utilities:     return 'Utilities';
      case ExpenseCategory.entertainment: return 'Entertainment';
      case ExpenseCategory.other:         return 'Other';
    }
  }
}