import 'package:expense_splitter/models/group.dart';
import 'package:hive/hive.dart';

class ExpenseRepository {
  static const String _groupBoxName = 'groups';

  /// Initialize Hive and open the groups box
  Future<void> initialize() async {
    if (!Hive.isBoxOpen(_groupBoxName)) {
      await Hive.openBox(_groupBoxName);
    }
  }

  /// Save a group to the database
  Future<void> saveGroup(Group group) async {
    final box = Hive.box(_groupBoxName);
    await box.put(group.id, group);
  }

  /// Load a specific group by ID
  Future<Group?> loadGroup(String groupId) async {
    final box = Hive.box(_groupBoxName);
    return box.get(groupId);
  }

  /// Load all groups
  Future<List<Group>> loadAllGroups() async {
    final box = Hive.box(_groupBoxName);
    final values = box.values.toList();
    return values.cast<Group>();
  }

  /// Delete a group by ID
  Future<void> deleteGroup(String groupId) async {
    final box = Hive.box(_groupBoxName);
    await box.delete(groupId);
  }

  /// Check if a group exists
  Future<bool> groupExists(String groupId) async {
    final box = Hive.box(_groupBoxName);
    return box.containsKey(groupId);
  }
}
