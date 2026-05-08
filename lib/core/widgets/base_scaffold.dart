import 'package:flutter/material.dart';
import 'app_drawer.dart';

class BaseScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;

  const BaseScaffold({
    super.key,
    this.title = 'Burgess GO',
    required this.body,
    this.floatingActionButton,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      drawer: const AppDrawer(),
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
    );
  }
}
