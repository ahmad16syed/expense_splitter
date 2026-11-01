import 'package:hive/hive.dart';

part 'member.g.dart';

@HiveType(typeId: 0)
class Member {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String color;

  Member({required this.id, required this.name, required this.color});
}
