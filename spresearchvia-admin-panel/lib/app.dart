import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'config/navigation.config.dart';
import 'config/theme.config.dart';
import 'config/app.config.dart';
import 'initial_binding.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.login,
      getPages: appPages,
      initialBinding: InitialBinding(),
      theme: AppTheme.lightTheme,
      defaultTransition: Transition.noTransition,
      transitionDuration: Duration.zero,
    );
  }
}
