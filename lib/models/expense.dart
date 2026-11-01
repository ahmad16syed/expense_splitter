import 'package:hive/hive.dart';
import 'member.dart';

part 'expense.g.dart';

@HiveType(typeId: 1)
class Expense {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final Member paidBy;

  @HiveField(4)
  final List<Member> splitBetween;

  @HiveField(5)
  final DateTime date;

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.splitBetween,
    required this.date,
  });
}
