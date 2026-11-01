import 'package:expense_splitter/models/expense.dart';
import 'package:expense_splitter/models/member.dart';

abstract class ExpenseEvent {}

// Event: User creates a new group
class CreateGroupEvent extends ExpenseEvent {
  final String groupName;
  final List<Member> members;

  CreateGroupEvent({required this.groupName, required this.members});
}

// Event: User adds an expense
class AddExpenseEvent extends ExpenseEvent {
  final Expense expense;

  AddExpenseEvent(this.expense);
}

// Event: User deletes an expense
class DeleteExpenseEvent extends ExpenseEvent {
  final String expenseId;

  DeleteExpenseEvent(this.expenseId);
}

// Event: User updates an expense
class UpdateExpenseEvent extends ExpenseEvent {
  final String expenseId;
  final Expense updatedExpense;

  UpdateExpenseEvent({required this.expenseId, required this.updatedExpense});
}

// Event: Load a saved group
class LoadGroupEvent extends ExpenseEvent {
  final String groupId;

  LoadGroupEvent(this.groupId);
}

// Event: Load all saved groups
class LoadAllGroupsEvent extends ExpenseEvent {}

// Event: Delete entire group
class DeleteGroupEvent extends ExpenseEvent {
  final String groupId;

  DeleteGroupEvent(this.groupId);
}

// Event: User renames the trip and/or changes its members
class UpdateGroupEvent extends ExpenseEvent {
  final String groupId;
  final String name;
  final List<Member> members;

  UpdateGroupEvent({
    required this.groupId,
    required this.name,
    required this.members,
  });
}
