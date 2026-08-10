import 'package:flutter/material.dart';

class ResourceCard extends StatelessWidget{
  const ResourceCard({super.key});

  @override
  Widget build(BuildContext context){
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Text('Resource card'),
      ),
    );
  }
}