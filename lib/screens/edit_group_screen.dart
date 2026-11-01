import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../bloc/expense_bloc.dart';
import '../bloc/expense_event.dart';
import '../bloc/expense_state.dart';
import '../models/group.dart';
import '../models/member.dart';

class EditGroupScreen extends StatefulWidget {
  final Group group;

  const EditGroupScreen({super.key, required this.group});

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

/// One row in the members list. Existing members keep their original
/// Member, so their id and color stay the same. New members have none.
class _MemberField {
  final Member? original;
  final TextEditingController controller;

  _MemberField({this.original, required String name})
    : controller = TextEditingController(text: name);
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  static const List<String> _colors = [
    'red',
    'blue',
    'green',
    'orange',
    'purple',
    'teal',
    'pink',
    'brown',
  ];

  late final TextEditingController _nameController;
  late final List<_MemberField> _fields;
  final _newMemberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    _fields = widget.group.members
        .map((m) => _MemberField(original: m, name: m.name))
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _newMemberController.dispose();
    for (final f in _fields) {
      f.controller.dispose();
    }
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// True if this member is the payer or in the split of any expense.
  bool _isUsed(String memberId) {
    return widget.group.expenses.any(
      (e) =>
          e.paidBy.id == memberId ||
          e.splitBetween.any((m) => m.id == memberId),
    );
  }

  void _addMember() {
    final name = _newMemberController.text.trim();
    if (name.isEmpty) return;

    final alreadyExists = _fields.any(
      (f) => f.controller.text.trim().toLowerCase() == name.toLowerCase(),
    );
    if (alreadyExists) {
      _showMessage('$name is already in the trip');
      return;
    }

    setState(() {
      _fields.add(_MemberField(name: name));
      _newMemberController.clear();
    });
  }

  void _removeField(int index) {
    final field = _fields[index];

    // Check here too, so the user sees the reason right away.
    // The BLoC checks it again as a safety net.
    if (field.original != null && _isUsed(field.original!.id)) {
      _showMessage(
        '${field.original!.name} is part of an expense. '
        'Edit or delete those first.',
      );
      return;
    }

    if (_fields.length <= 2) {
      _showMessage('A trip needs at least 2 members');
      return;
    }

    setState(() {
      field.controller.dispose();
      _fields.removeAt(index);
    });
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Please enter a trip name');
      return;
    }

    final members = <Member>[];
    for (final field in _fields) {
      final text = field.controller.text.trim();
      if (text.isEmpty) continue;

      final original = field.original;
      if (original != null) {
        // Keep the same id and color, so existing expenses still match
        members.add(Member(id: original.id, name: text, color: original.color));
      } else {
        members.add(
          Member(
            id: const Uuid().v4(),
            name: text,
            color: _colors[members.length % _colors.length],
          ),
        );
      }
    }

    if (members.length < 2) {
      _showMessage('Add at least 2 members');
      return;
    }

    context.read<ExpenseBloc>().add(
      UpdateGroupEvent(groupId: widget.group.id, name: name, members: members),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit trip')),
      body: BlocListener<ExpenseBloc, ExpenseState>(
        listener: (context, state) {
          if (state is GroupUpdated) {
            Navigator.of(context).pop(); // back to the detail screen
          } else if (state is ExpenseError) {
            _showMessage(state.message);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Trip name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Members',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              for (int i = 0; i < _fields.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _fields[i].controller,
                          decoration: InputDecoration(
                            labelText: 'Member ${i + 1}',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        tooltip: 'Remove member',
                        onPressed: () => _removeField(i),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newMemberController,
                      decoration: const InputDecoration(
                        labelText: 'New member name',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _addMember(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_add),
                    tooltip: 'Add member',
                    onPressed: _addMember,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              BlocBuilder<ExpenseBloc, ExpenseState>(
                builder: (context, state) {
                  final isLoading = state is ExpenseLoading;
                  return ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save changes'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
