import 'package:flutter/material.dart';
import '../widgets/resource_card.dart';
import '../widgets/server_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {

    var colors = Theme.of(context).colorScheme;

    return Container(
      color: colors.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children : [
      
            const Text(
              'System',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
      
            Row(
              children: [
                ResourceCard(
                  title: 'CPU',
                  value: '23%',
                ),
      
                ResourceCard(
                  title: 'MEM',
                  value: '20%',
                ),
      
                ResourceCard(
                  title: 'NET',
                  value: '0.5%',
                ),
              ],
            ),
            const SizedBox(height: 32),
      
            const Text(
              'Servers',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
      
            const ServerCard(
              name: 'Django Server',
              port: 8000,
              running: false,
            ),
            // const SizedBox(height: 12),
      
            const ServerCard(
              name: 'Minecraft Server',
              port: 25565,
              running: true,
            ),    
            const ServerCard(
              name: 'Minecraft Server',
              port: 25565,
              running: true,
            ),    
            const ServerCard(
              name: 'Minecraft Server',
              port: 25565,
              running: true,
            ),    
            const ServerCard(
              name: 'Minecraft Server',
              port: 25565,
              running: true,
            ),    
            const ServerCard(
              name: 'Minecraft Server',
              port: 25565,
              running: true,
            ),    
            const ServerCard(
              name: 'Minecraft Server',
              port: 25565,
              running: true,
            ),    
        ]
        ),
      ),
    );
  }
}