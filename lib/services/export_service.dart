import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'expense_service.dart';

class ExportService {
  static Future<String> exportCurrentMonth() async {
    final now = DateTime.now();
    final monthLabel = DateFormat('MMMM yyyy').format(now);
    final fmt = DateFormat('MMM dd, yyyy');

    // Filter expenses for the current month only
    final all = ExpenseService.getAllExpenses();
    final monthly = all.where(
      (e) => e.date.year == now.year && e.date.month == now.month
    ).toList()..sort((a, b) => a.date.compareTo(b.date));

    // Build the report as plain text
    final buf = StringBuffer();
    buf.writeln('========================================');
    buf.writeln(' SPENDWISE EXPENSE REPORT');
    buf.writeln(' $monthLabel');
    buf.writeln('========================================');
    buf.writeln();

    double total = 0;
    for (final e in monthly) {
      buf.writeln('${fmt.format(e.date).padRight(16)} '
          '${e.categoryName.padRight(14)} '
          '₱${e.amount.toStringAsFixed(2).padLeft(10)} '
          ' ${e.title}');
      total += e.amount;
    }

    buf.writeln();
    buf.writeln('----------------------------------------');
    buf.writeln('${' ' * 32}TOTAL ₱${total.toStringAsFixed(2)}');
    buf.writeln('========================================');
    buf.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(now)}');

    // Save to the app's documents directory
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'spendwise_${now.year}_${now.month.toString().padLeft(2, '0')}.txt';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(buf.toString());

    return file.path;
  }
}