import 'package:expense_splitter/screens/create_group_screen.dart';
import 'package:expense_splitter/screens/group_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/expense_bloc.dart';
import '../bloc/expense_event.dart';
import '../bloc/expense_state.dart';
import '../models/group.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Trips')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
          if (context.mounted) {
            context.read<ExpenseBloc>().add(LoadAllGroupsEvent());
          }
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<ExpenseBloc>().add(LoadAllGroupsEvent());
        },
        child: BlocBuilder<ExpenseBloc, ExpenseState>(
          builder: (context, state) {
            if (state is ExpenseLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ExpenseError) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(state.message, textAlign: TextAlign.center),
                  ),
                ],
              );
            }

            if (state is AllGroupsLoaded) {
              if (state.groups.isEmpty) {
                return ListView(
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No trips yet. Tap + to create one.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              }

              return ListView.builder(
                itemCount: state.groups.length,
                itemBuilder: (context, index) =>
                    _GroupCard(group: state.groups[index]),
              );
            }

            // Initial state, before groups are loaded
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final Group group;

  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(group.name),
        subtitle: Text(
          '${group.members.length} members · ${group.expenses.length} expenses',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GroupDetailScreen(groupId: group.id),
            ),
          );
          if (context.mounted) {
            context.read<ExpenseBloc>().add(LoadAllGroupsEvent());
          }
        },
      ),
    );
  }
}
