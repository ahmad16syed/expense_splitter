import 'package:expense_splitter/models/group.dart';
import 'package:expense_splitter/models/settlement.dart';

class SettlementCalculator {
  /// Calculate who owes whom based on all expenses in a group
  static List<Settlement> calculateSettlements(Group group) {
    // Step 1: Check if there are any expenses
    if (group.expenses.isEmpty) return [];

    // STEP 1: Calculate total paid by each member
    Map<String, double> totalPaid = {};
    for (var member in group.members) {
      totalPaid[member.id] = 0;
    }

    for (var expense in group.expenses) {
      totalPaid[expense.paidBy.id] =
          (totalPaid[expense.paidBy.id] ?? 0) + expense.amount;
    }

    // STEP 2: Calculate how much each member SHOULD pay.
    // Each expense is split only among the people in its own splitBetween list.
    Map<String, double> shouldPay = {};
    for (var member in group.members) {
      shouldPay[member.id] = 0;
    }

    for (var expense in group.expenses) {
      if (expense.splitBetween.isEmpty) continue;

      double sharePerPerson = expense.amount / expense.splitBetween.length;

      for (var member in expense.splitBetween) {
        shouldPay[member.id] = (shouldPay[member.id] ?? 0) + sharePerPerson;
      }
    }

    // STEP 3: Calculate balance (positive = owed money, negative = owes money)
    Map<String, double> balance = {};
    for (var member in group.members) {
      balance[member.id] = (totalPaid[member.id] ?? 0) - shouldPay[member.id]!;
    }

    // STEP 4: Separate creditors and debtors
    List<MapEntry<String, double>> creditors = [];
    List<MapEntry<String, double>> debtors = [];

    balance.forEach((memberId, amount) {
      if (amount > 0.01) {
        creditors.add(MapEntry(memberId, amount));
      } else if (amount < -0.01) {
        debtors.add(MapEntry(memberId, -amount));
      }
    });

    // STEP 5: Match debtors with creditors
    List<Settlement> settlements = [];

    for (var debtor in debtors) {
      double debtAmount = debtor.value;

      for (int i = 0; i < creditors.length; i++) {
        if (debtAmount <= 0.01) break;

        var creditor = creditors[i];
        double settleAmount = debtAmount > creditor.value
            ? creditor.value
            : debtAmount;

        settlements.add(
          Settlement(
            from: group.members.firstWhere((m) => m.id == debtor.key),
            to: group.members.firstWhere((m) => m.id == creditor.key),
            amount: settleAmount,
          ),
        );

        debtAmount -= settleAmount;
        creditors[i] = MapEntry(creditor.key, creditor.value - settleAmount);
      }
    }

    return settlements;
  }
}
