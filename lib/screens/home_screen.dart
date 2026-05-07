import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import '../widgets/expense_tile.dart';
import 'add_expense_screen.dart';
import 'edit_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ExpenseCategory? _selectedCategory;

  String _label(ExpenseCategory? cat) {
    if (cat == null) return 'All';
    switch (cat) {
      case ExpenseCategory.food: return 'Food';
      case ExpenseCategory.transport: return 'Transport';
      case ExpenseCategory.shopping: return 'Shopping';
      case ExpenseCategory.utilities: return 'Utilities';
      case ExpenseCategory.entertainment: return 'Entertainment';
      case ExpenseCategory.other: return 'Other';
    }
  }

  // ── BUDGET HELPERS ──────────────────────────────────────────────────
  double _getBudget() {
    final box = Hive.box('settings');
    return (box.get('monthly_budget') ?? 0.0) as double;
  }

Future<void> _showSetBudgetDialog() async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _BudgetDialog(initialBudget: _getBudget()),
  );
}

  void _checkBudgetAlert(double totalSpent, double budget) {
    if (budget <= 0) return;
    final pct = totalSpent / budget;
    if (pct >= 0.8) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            '⚠️ Budget Alert: You\'ve used ${(pct * 100).toStringAsFixed(0)}% of your monthly budget!',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SpendWise',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // ── SET BUDGET BUTTON ──
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Set Budget',
            onPressed: _showSetBudgetDialog,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: 'SpendWise',
              applicationVersion: '1.0.0',
              children: [
                const Text('A personal expense tracker built with Hive.')
              ],
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<Expense>>(
        valueListenable: ExpenseService.listenable,
        builder: (context, box, _) {
          final double total =
              box.values.fold(0.0, (s, e) => s + e.amount);
          final double budget = _getBudget();
          final double pct =
              budget > 0 ? (total / budget).clamp(0.0, 1.0) : 0.0;

          // Check and show alert if needed
          _checkBudgetAlert(total, budget);

          final List<Expense> expenses = _selectedCategory == null
              ? ExpenseService.getAllExpenses()
              : ExpenseService.getExpensesByCategory(_selectedCategory!);

          expenses.sort((a, b) => b.date.compareTo(a.date));

          return Column(
            children: [
              _buildSummaryCard(total, box.length, budget, pct),
              _buildFilterChips(),
              Expanded(child: _buildExpenseList(expenses)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  Widget _buildSummaryCard(
      double total, int count, double budget, double pct) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      elevation: 4,
      color: Theme.of(context).colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── TOP ROW: label + total ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Spending',
                        style:
                            TextStyle(fontSize: 14, color: Colors.black54)),
                    Text('$count expense${count == 1 ? '' : 's'}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black45)),
                  ],
                ),
                Text(
                  '₱${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo),
                ),
              ],
            ),

            // ── BUDGET PROGRESS BAR (only shown if budget is set) ──
            if (budget > 0) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Budget: ₱${budget.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54),
                  ),
                  Text(
                    '${(pct * 100).toStringAsFixed(0)}% used',
                    style: TextStyle(
                      fontSize: 12,
                      color: pct >= 0.8 ? Colors.red : Colors.black54,
                      fontWeight: pct >= 0.8
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: Colors.grey[300],
                  color: pct >= 0.8 ? Colors.red : Colors.indigo,
                  minHeight: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final categories = [null, ...ExpenseCategory.values];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: categories
            .map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_label(cat)),
                    selected: _selectedCategory == cat,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = cat),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildExpenseList(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No expenses yet!',
                style:
                    TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Tap the button below to add your first expense.',
                style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (ctx, i) {
        final expense = expenses[i];
        final int key = expense.key as int;
        return ExpenseTile(
          expense: expense,
          onDelete: () => ExpenseService.deleteExpense(key),
          onEdit: () => Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => EditExpenseScreen(
                  expense: expense, expenseKey: key),
            ),
          ),
        );
      },
    );
  }
}

class _BudgetDialog extends StatefulWidget {
  final double initialBudget;
  const _BudgetDialog({required this.initialBudget});

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.initialBudget > 0
          ? widget.initialBudget.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Monthly Budget'),
      content: TextField(
        controller: _ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Budget Amount',
          prefixText: '₱ ',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final val = double.tryParse(_ctrl.text.trim());
            if (val != null && val > 0) {
              Hive.box('settings').put('monthly_budget', val);
            }
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}