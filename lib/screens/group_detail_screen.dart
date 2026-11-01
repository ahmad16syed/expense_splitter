import 'package:expense_splitter/services/report_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';

import '../bloc/expense_bloc.dart';
import '../bloc/expense_event.dart';
import '../bloc/expense_state.dart';
import '../models/expense.dart';
import '../models/group.dart';
import '../models/settlement.dart';
import 'add_expense_screen.dart';
import 'edit_group_screen.dart';

/// Shows a yes/no dialog. Returns true only if the user confirms.
Future<bool> _confirm(BuildContext context, String message) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result ?? false;
}

class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ExpenseBloc>().add(LoadGroupEvent(widget.groupId));
  }

  ({Group group, List<Settlement> settlements})? _extract(ExpenseState state) {
    if (state is GroupLoaded ||
        state is ExpenseAdded ||
        state is ExpenseUpdated ||
        state is ExpenseDeleted ||
        state is GroupUpdated) {
      final s = state as dynamic;
      return (
        group: s.group as Group,
        settlements: s.settlements as List<Settlement>,
      );
    }
    return null;
  }

  void _openAddExpense(Group group, {Expense? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(group: group, existing: existing),
      ),
    );
  }

  Future<void> _deleteExpense(Expense expense) async {
    final ok = await _confirm(context, 'Delete "${expense.description}"?');
    if (ok && mounted) {
      context.read<ExpenseBloc>().add(DeleteExpenseEvent(expense.id));
    }
  }

  Future<void> _deleteTrip(Group group) async {
    final ok = await _confirm(
      context,
      'Delete "${group.name}" and all its expenses? This cannot be undone.',
    );
    if (ok && mounted) {
      context.read<ExpenseBloc>().add(DeleteGroupEvent(group.id));
    }
  }

  Future<void> _downloadReport(
    Group group,
    List<Settlement> settlements,
  ) async {
    final bytes = await buildGroupReport(group, settlements);
    await Printing.sharePdf(bytes: bytes, filename: '${group.name}_report.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExpenseBloc, ExpenseState>(
      listener: (context, state) {
        if (state is ExpenseError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is AllGroupsLoaded) {
          // The trip was deleted, so leave this screen
          Navigator.of(context).pop();
        }
      },
      child: BlocBuilder<ExpenseBloc, ExpenseState>(
        builder: (context, state) {
          final view = _extract(state);

          return Scaffold(
            appBar: AppBar(
              title: Text(view?.group.name ?? 'Trip'),
              actions: [
                if (view != null) ...[
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf),
                    tooltip: 'Download report',
                    onPressed: () =>
                        _downloadReport(view.group, view.settlements),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit trip',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EditGroupScreen(group: view.group),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete trip',
                    onPressed: () => _deleteTrip(view.group),
                  ),
                ],
              ],
            ),
            floatingActionButton: view == null
                ? null
                : FloatingActionButton.extended(
                    onPressed: () => _openAddExpense(view.group),
                    icon: const Icon(Icons.add),
                    label: const Text('Add expense'),
                  ),
            body: view == null
                ? _buildFallback(state)
                : _buildContent(view.group, view.settlements),
          );
        },
      ),
    );
  }

  Widget _buildFallback(ExpenseState state) {
    if (state is ExpenseError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(state.message, textAlign: TextAlign.center),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildContent(Group group, List<Settlement> settlements) {
    final expenses = group.expenses;

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        const _SectionHeader('Who owes whom'),
        if (settlements.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Nothing to settle yet.'),
          )
        else
          ...settlements.map((s) => _SettlementTile(settlement: s)),
        const _SectionHeader('Expenses'),
        if (expenses.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('No expenses yet. Tap "Add expense" to start.'),
          )
        else
          ...expenses.map(
            (e) => _ExpenseTile(
              expense: e,
              onEdit: () => _openAddExpense(group, existing: e),
              onDelete: () => _deleteExpense(e),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SettlementTile extends StatelessWidget {
  final Settlement settlement;

  const _SettlementTile({required this.settlement});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        title: Text('${settlement.from.name} owes ${settlement.to.name}'),
        trailing: Text(
          '₹${settlement.amount.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseTile({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        title: Text(expense.description),
        subtitle: Text(
          'Paid by ${expense.paidBy.name} · split ${expense.splitBetween.length} ways',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${expense.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit expense',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete expense',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
