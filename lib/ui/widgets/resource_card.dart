import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';


class ResourceCard extends StatelessWidget{
  final String title;
  final String value;
  final List<double> data;


  const ResourceCard({
    super.key,
    required this.title,
    required this.value,
    required this.data,
  });


  @override
  Widget build(BuildContext context){
    final resourceValue = int.tryParse(value) ?? 0;

    var colors = Theme.of(context).colorScheme;

    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: resourceValue > 70 ? Colors.red.withValues(alpha: 0.25) : colors.outline.withValues(alpha: 0.25)
          )
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 2),
              Text(
                '$value%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: resourceValue > 70 ? colors.error : colors.tertiary,
                ),
              ),

              SizedBox(
                height: 60,
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: data
                          .asMap()
                          .entries
                          .map(
                            (entry) => FlSpot(
                              entry.key.toDouble(),
                              entry.value,
                            ),
                          )
                          .toList(),
                        isCurved: true,
                        barWidth: 2,
                        color: resourceValue > 70 ? colors.onError : colors.tertiary,
                      )
                    ],
                    titlesData: const FlTitlesData(
                      show: false,
                    ),
                    borderData: FlBorderData(
                      show: false,
                    ),
                    gridData: const FlGridData(
                      show: false,
                    ),
                    minY: 0,
                    minX: 0,
                  )
                )
              )
            ],
          )
        )
      ),
    );
  }
}