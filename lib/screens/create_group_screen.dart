import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../bloc/expense_bloc.dart';
import '../bloc/expense_event.dart';
import '../bloc/expense_state.dart';
import '../models/member.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
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

  final _nameController = TextEditingController();
  final List<TextEditingController> _memberControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _memberControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addMemberField() {
    setState(() => _memberControllers.add(TextEditingController()));
  }

  void _removeMemberField(int index) {
    if (_memberControllers.length <= 2) return; // keep at least 2 fields
    setState(() {
      _memberControllers[index].dispose();
      _memberControllers.removeAt(index);
    });
  }

  void _submit() {
    final groupName = _nameController.text.trim();
    final names = _memberControllers
        .map((c) => c.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    if (groupName.isEmpty) {
      _showMessage('Please enter a trip name');
      return;
    }
    if (names.length < 2) {
      _showMessage('Add at least 2 members');
      return;
    }

    final uuid = const Uuid();
    final members = [
      for (int i = 0; i < names.length; i++)
        Member(
          id: uuid.v4(),
          name: names[i],
          color: _colors[i % _colors.length],
        ),
    ];

    context.read<ExpenseBloc>().add(
      CreateGroupEvent(groupName: groupName, members: members),
    );
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Trip')),
      body: BlocListener<ExpenseBloc, ExpenseState>(
        listener: (context, state) {
          if (state is GroupCreated) {
            Navigator.of(context).pop(); // go back to the home list
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
                  hintText: 'e.g. Dubai Trip',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Members',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              for (int i = 0; i < _memberControllers.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _memberControllers[i],
                          decoration: InputDecoration(
                            labelText: 'Member ${i + 1}',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => _removeMemberField(i),
                      ),
                    ],
                  ),
                ),
              TextButton.icon(
                onPressed: _addMemberField,
                icon: const Icon(Icons.person_add),
                label: const Text('Add member'),
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
                        : const Text('Create Trip'),
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
