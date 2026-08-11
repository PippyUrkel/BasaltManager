import 'package:flutter/material.dart';

class PortList extends StatelessWidget {
  const PortList({super.key});

  @override
  Widget build(BuildContext context){
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Ports'),
      ),
    );
  }
}