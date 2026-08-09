import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/images/sp_logo.png', fit: BoxFit.cover);
  }
}
