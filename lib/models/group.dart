import 'package:hive/hive.dart';
import 'member.dart';
import 'expense.dart';

part 'group.g.dart';

@HiveType(typeId: 2)
class Group {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final List<Member> members;

  @HiveField(3)
  final List<Expense> expenses;

  Group({
    required this.id,
    required this.name,
    required this.members,
    required this.expenses,
  });
}
