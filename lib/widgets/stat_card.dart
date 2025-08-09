import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  var label;
  var value;

  StatCard(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    var scheme = Theme.of(context).colorScheme;
    return Container(
      width: 80,
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 14)),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20)),
        ],
      ),
    );
  }
}
