import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../bloc/expense_bloc.dart';
import '../bloc/expense_event.dart';
import '../bloc/expense_state.dart';
import '../models/expense.dart';
import '../models/group.dart';

class AddExpenseScreen extends StatefulWidget {
  final Group group;

  /// If null, the screen adds a new expense.
  /// If set, the screen edits this expense.
  final Expense? existing;

  const AddExpenseScreen({super.key, required this.group, this.existing});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  String? _paidById;
  late final Set<String> _splitIds;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;

    if (e != null) {
      // Editing: fill the form with the saved values
      _descriptionController.text = e.description;
      _amountController.text = e.amount == e.amount.roundToDouble()
          ? e.amount.toStringAsFixed(0)
          : e.amount.toString();
      _paidById = e.paidBy.id;
      _splitIds = e.splitBetween.map((m) => m.id).toSet();
    } else {
      // Adding: everyone is included in the split by default
      _splitIds = widget.group.members.map((m) => m.id).toSet();
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _toggleSplit(String memberId, bool? selected) {
    setState(() {
      if (selected == true) {
        _splitIds.add(memberId);
      } else {
        _splitIds.remove(memberId);
      }
    });
  }

  void _submit() {
    final description = _descriptionController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (description.isEmpty) {
      _showMessage('Please enter a description');
      return;
    }
    if (amount == null || amount <= 0) {
      _showMessage('Please enter a valid amount');
      return;
    }
    if (_paidById == null) {
      _showMessage('Please choose who paid');
      return;
    }
    if (_splitIds.isEmpty) {
      _showMessage('Choose at least one person to split with');
      return;
    }

    final payer = widget.group.members.firstWhere((m) => m.id == _paidById);
    final splitBetween = widget.group.members
        .where((m) => _splitIds.contains(m.id))
        .toList();

    final existing = widget.existing;

    final expense = Expense(
      // Editing keeps the same id and date. Adding creates new ones.
      id: existing?.id ?? const Uuid().v4(),
      description: description,
      amount: amount,
      paidBy: payer,
      splitBetween: splitBetween,
      date: existing?.date ?? DateTime.now(),
    );

    final ExpenseEvent event = existing == null
        ? AddExpenseEvent(expense)
        : UpdateExpenseEvent(expenseId: existing.id, updatedExpense: expense);

    context.read<ExpenseBloc>().add(event);
  }

  @override
  Widget build(BuildContext context) {
    final members = widget.group.members;
    final isEditing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit expense' : 'Add expense')),
      body: BlocListener<ExpenseBloc, ExpenseState>(
        listener: (context, state) {
          if (state is ExpenseAdded || state is ExpenseUpdated) {
            Navigator.of(context).pop(); // back to the detail screen
          } else if (state is ExpenseError) {
            _showMessage(state.message);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g. Hotel',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _paidById,
                decoration: const InputDecoration(
                  labelText: 'Paid by',
                  border: OutlineInputBorder(),
                ),
                items: members
                    .map(
                      (m) => DropdownMenuItem(value: m.id, child: Text(m.name)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _paidById = value),
              ),
              const SizedBox(height: 24),
              const Text(
                'Split between',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              for (final m in members)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(m.name),
                  value: _splitIds.contains(m.id),
                  onChanged: (selected) => _toggleSplit(m.id, selected),
                ),
              const SizedBox(height: 24),
              BlocBuilder<ExpenseBloc, ExpenseState>(
                builder: (context, state) {
                  final isLoading = state is ExpenseLoading;
                  return ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEditing ? 'Save changes' : 'Save expense'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
