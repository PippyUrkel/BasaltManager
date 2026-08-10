import 'package:flutter/material.dart';

class ServerCard extends StatelessWidget{
  const ServerCard({super.key});

  @override
  Widget build(BuildContext context){
    return const Card( 
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Text('Server Card'),
      ),
    );
  }
}