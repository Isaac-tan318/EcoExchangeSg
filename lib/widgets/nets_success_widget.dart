import 'package:flutter/material.dart';

class NETSSuccess extends StatelessWidget {
  const NETSSuccess({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Align(
          alignment: Alignment.center,
          child: Image.asset(
            'assets/images/greenTick.png',
            width: MediaQuery.of(context).size.width * 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Transaction Successful!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
