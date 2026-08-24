import 'package:flutter/material.dart';
import 'ui/shell/app_shell.dart';
import 'core/theme/theme.dart';

class ServerManagerApp extends StatelessWidget {
  const ServerManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Basalt Server Manager',
      theme: appTheme,
      home: const AppShell(),
    );
  }
}