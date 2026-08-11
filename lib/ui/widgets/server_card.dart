import 'package:flutter/material.dart';

class ServerCard extends StatelessWidget{
  final String name;
  final int port;
  final bool running;

  const ServerCard({
    super.key,
    required this.name,
    required this.port,
    required this.running,
  });

  @override
  Widget build(BuildContext context){

    var colors = Theme.of(context).colorScheme;

    return Card(
      color: running ? colors.surfaceContainerHigh : colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.primaryFixedDim,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Port $port'),
                ],
              ),
            ),
            Text(
              running ? 'Running' : 'Stopped',
              style: TextStyle(
                color: running ? Colors.lightGreen : Colors.red,
              )
            ),
          ],
        ),
      ),
    );
  }
}