import 'package:flutter/material.dart';
import 'ui/screens/dashboard_screen.dart';
import 'ui/shell/app_shell.dart';
import 'theme.dart';

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