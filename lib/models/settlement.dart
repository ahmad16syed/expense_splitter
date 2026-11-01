import 'package:expense_splitter/models/member.dart';

class Settlement {
  final Member from;
  final Member to;
  final double amount;

  Settlement({required this.from, required this.to, required this.amount});

  @override
  String toString() =>
      '${from.name} owes ${to.name}: ₹${amount.toStringAsFixed(2)}';
}
