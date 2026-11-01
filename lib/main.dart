import 'package:expense_splitter/bloc/expense_event.dart';
import 'package:expense_splitter/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'bloc/expense_bloc.dart';
import 'models/expense.dart';
import 'models/group.dart';
import 'models/member.dart';
import 'repositories/expense_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(MemberAdapter());
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(GroupAdapter());

  final repository = ExpenseRepository();
  await repository.initialize();

  runApp(MyApp(repository: repository));
}

class MyApp extends StatelessWidget {
  final ExpenseRepository repository;

  const MyApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExpenseBloc(repository)..add(LoadAllGroupsEvent()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Expense Splitter',
        home: const HomeScreen(),
      ),
    );
  }
}
