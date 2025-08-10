import 'package:flutter/material.dart';

class NETSFail extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Align(
          alignment: Alignment.center,
          child: Image.asset(
            'assets/images/redCross.png',
            width: MediaQuery.of(context).size.width * 0.5,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Transaction Failed!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}