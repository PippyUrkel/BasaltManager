import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';
import '../screens/servers_screen.dart';
import '../screens/settings_screen.dart';

class AppShell extends StatefulWidget{

  const AppShell({super.key});
  
  @override
  State<AppShell> createState() => _AppShellState();

}


class _AppShellState extends State<AppShell> {
  static const List<Widget> _screens = [
    DashboardScreen(),
    ServersScreen(),
    SettingsScreen(),
  ];

  int _selectedIndex = 0;


  @override
  Widget build(BuildContext context){

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 20,
        
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard'
          ),
          NavigationDestination(
            icon: Icon(Icons.dns_outlined),
            selectedIcon: Icon(Icons.dns),
            label: 'Flakes'
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings'
          )
        ],
      ),
    );
  }
}