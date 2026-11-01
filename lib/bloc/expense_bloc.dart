import 'package:expense_splitter/bloc/expense_event.dart';
import 'package:expense_splitter/bloc/expense_state.dart';
import 'package:expense_splitter/models/expense.dart';
import 'package:expense_splitter/models/group.dart';
import 'package:expense_splitter/repositories/expense_repository.dart';
import 'package:expense_splitter/services/settlement_calculator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final ExpenseRepository _repository;

  // The group the user is currently working on
  Group? _currentGroup;

  ExpenseBloc(this._repository) : super(ExpenseInitial()) {
    on<CreateGroupEvent>(_onCreateGroup);
    on<AddExpenseEvent>(_onAddExpense);
    on<UpdateExpenseEvent>(_onUpdateExpense);
    on<DeleteExpenseEvent>(_onDeleteExpense);
    on<LoadGroupEvent>(_onLoadGroup);
    on<LoadAllGroupsEvent>(_onLoadAllGroups);
    on<DeleteGroupEvent>(_onDeleteGroup);
    on<UpdateGroupEvent>(_onUpdateGroup);
  }

  // ---------- Helpers ----------

  /// Builds a new Group with a different expense list.
  /// We never modify the old group; we create a new one.
  Group _withExpenses(Group group, List<Expense> expenses) {
    return Group(
      id: group.id,
      name: group.name,
      members: group.members,
      expenses: expenses,
    );
  }

  /// Saves the current group and returns it.
  Future<Group> _save(Group group) async {
    await _repository.saveGroup(group);
    _currentGroup = group;
    return group;
  }

  // ---------- Handlers ----------

  Future<void> _onCreateGroup(
    CreateGroupEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading());
    try {
      final group = Group(
        id: const Uuid().v4(),
        name: event.groupName,
        members: event.members,
        expenses: [],
      );
      await _save(group);
      emit(GroupCreated(group));
    } catch (e) {
      emit(ExpenseError('Could not create group: $e'));
    }
  }

  Future<void> _onAddExpense(
    AddExpenseEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    final group = _currentGroup;
    if (group == null) {
      emit(ExpenseError('No group selected'));
      return;
    }

    emit(ExpenseLoading());
    try {
      final updated = _withExpenses(group, [...group.expenses, event.expense]);
      await _save(updated);

      final settlements = SettlementCalculator.calculateSettlements(updated);
      emit(ExpenseAdded(group: updated, settlements: settlements));
    } catch (e) {
      emit(ExpenseError('Could not add expense: $e'));
    }
  }

  Future<void> _onUpdateExpense(
    UpdateExpenseEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    final group = _currentGroup;
    if (group == null) {
      emit(ExpenseError('No group selected'));
      return;
    }

    emit(ExpenseLoading());
    try {
      final updatedList = group.expenses.map((e) {
        return e.id == event.expenseId ? event.updatedExpense : e;
      }).toList();

      final updated = _withExpenses(group, updatedList);
      await _save(updated);

      final settlements = SettlementCalculator.calculateSettlements(updated);
      emit(ExpenseUpdated(group: updated, settlements: settlements));
    } catch (e) {
      emit(ExpenseError('Could not update expense: $e'));
    }
  }

  Future<void> _onDeleteExpense(
    DeleteExpenseEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    final group = _currentGroup;
    if (group == null) {
      emit(ExpenseError('No group selected'));
      return;
    }

    emit(ExpenseLoading());
    try {
      final updatedList = group.expenses
          .where((e) => e.id != event.expenseId)
          .toList();

      final updated = _withExpenses(group, updatedList);
      await _save(updated);

      final settlements = SettlementCalculator.calculateSettlements(updated);
      emit(ExpenseDeleted(group: updated, settlements: settlements));
    } catch (e) {
      emit(ExpenseError('Could not delete expense: $e'));
    }
  }

  Future<void> _onLoadGroup(
    LoadGroupEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading());
    try {
      final group = await _repository.loadGroup(event.groupId);
      if (group == null) {
        emit(ExpenseError('Group not found'));
        return;
      }

      _currentGroup = group;
      final settlements = SettlementCalculator.calculateSettlements(group);
      emit(GroupLoaded(group: group, settlements: settlements));
    } catch (e) {
      emit(ExpenseError('Could not load group: $e'));
    }
  }

  Future<void> _onLoadAllGroups(
    LoadAllGroupsEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading());
    try {
      final groups = await _repository.loadAllGroups();
      emit(AllGroupsLoaded(groups));
    } catch (e) {
      emit(ExpenseError('Could not load groups: $e'));
    }
  }

  Future<void> _onDeleteGroup(
    DeleteGroupEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading());
    try {
      await _repository.deleteGroup(event.groupId);

      // If we deleted the group we were working on, forget it
      if (_currentGroup?.id == event.groupId) {
        _currentGroup = null;
      }

      final groups = await _repository.loadAllGroups();
      emit(AllGroupsLoaded(groups));
    } catch (e) {
      emit(ExpenseError('Could not delete group: $e'));
    }
  }

  /// Returns true if the member is the payer or part of the split
  /// of any expense in the group.
  bool _isMemberUsed(Group group, String memberId) {
    return group.expenses.any(
      (e) =>
          e.paidBy.id == memberId ||
          e.splitBetween.any((m) => m.id == memberId),
    );
  }

  Future<void> _onUpdateGroup(
    UpdateGroupEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    final group = _currentGroup;
    if (group == null || group.id != event.groupId) {
      emit(ExpenseError('No group selected'));
      return;
    }

    // Business rule: a member can't be removed while an expense uses them.
    final newIds = event.members.map((m) => m.id).toSet();
    for (final old in group.members) {
      final wasRemoved = !newIds.contains(old.id);
      if (wasRemoved && _isMemberUsed(group, old.id)) {
        emit(
          ExpenseError(
            '${old.name} is part of an expense. Edit or delete those first.',
          ),
        );
        return;
      }
    }

    emit(ExpenseLoading());
    try {
      final updated = Group(
        id: group.id,
        name: event.name,
        members: event.members,
        expenses: group.expenses,
      );
      await _save(updated);

      final settlements = SettlementCalculator.calculateSettlements(updated);
      emit(GroupUpdated(group: updated, settlements: settlements));
    } catch (e) {
      emit(ExpenseError('Could not update trip: $e'));
    }
  }
}
