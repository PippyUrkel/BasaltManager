import 'package:flutter/material.dart';

import 'theme.dart';

class ServerManagerApp extends StatelessWidget {
  const ServerManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Basalt Server Manager',
      theme: appTheme,
      home: const Scaffold(
        body: Center(
          child: Text('Server Manager'),
          ),
      ),
    );
  }
}