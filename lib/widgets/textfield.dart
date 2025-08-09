import 'package:flutter/material.dart';

class Field extends StatelessWidget {
  final Widget child;
  final color;
  final EdgeInsetsGeometry? padding;
  const Field({super.key, required this.child, this.color, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: padding ?? EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color,
        border: Border.all(color: Colors.black),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class BorderlessField extends StatelessWidget {
  final Widget child;
  final color;
  const BorderlessField({super.key, required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color,
      ),
      child: child,
    );
  }
}
