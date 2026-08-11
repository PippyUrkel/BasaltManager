import 'package:flutter/material.dart';

class ResourceCard extends StatelessWidget{
  final String title;
  final String value;


  const ResourceCard({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context){
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              )
            ],
          )
        )
      ),
    );
  }
}