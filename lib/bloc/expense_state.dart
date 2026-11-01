import 'package:expense_splitter/models/group.dart';
import 'package:expense_splitter/models/settlement.dart';

abstract class ExpenseState {}

// Initial state - app just started
class ExpenseInitial extends ExpenseState {}

// Loading data
class ExpenseLoading extends ExpenseState {}

// Group created successfully
class GroupCreated extends ExpenseState {
  final Group group;

  GroupCreated(this.group);
}

// Expense added successfully - show updated settlements
class ExpenseAdded extends ExpenseState {
  final Group group;
  final List<Settlement> settlements;

  ExpenseAdded({required this.group, required this.settlements});
}

// Expense updated successfully
class ExpenseUpdated extends ExpenseState {
  final Group group;
  final List<Settlement> settlements;

  ExpenseUpdated({required this.group, required this.settlements});
}

// Expense deleted successfully
class ExpenseDeleted extends ExpenseState {
  final Group group;
  final List<Settlement> settlements;

  ExpenseDeleted({required this.group, required this.settlements});
}

// Group loaded successfully
class GroupLoaded extends ExpenseState {
  final Group group;
  final List<Settlement> settlements;

  GroupLoaded({required this.group, required this.settlements});
}

// All groups loaded successfully
class AllGroupsLoaded extends ExpenseState {
  final List<Group> groups;

  AllGroupsLoaded(this.groups);
}

// Error occurred
class ExpenseError extends ExpenseState {
  final String message;

  ExpenseError(this.message);
}

// Group name or members updated successfully
class GroupUpdated extends ExpenseState {
  final Group group;
  final List<Settlement> settlements;

  GroupUpdated({required this.group, required this.settlements});
}
