import 'package:flutter/material.dart';

import 'startup.dart';
import 'app.dart';

void main() async {
  await startup();
  runApp(const App());
}
