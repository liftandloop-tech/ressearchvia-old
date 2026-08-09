import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';


class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // Services and Controllers are initialized in startup.dart

    return GetMaterialApp(
      title: "SPResearchvia",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppTheme.backgroundWhite,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.backgroundWhite,
        ),
        fontFamily: 'Poppins',
      ),
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        final scale = mediaQueryData.size.width / 375.0;
        final scaleFactor = scale.clamp(0.85, 1.15);

        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaler: TextScaler.linear(scaleFactor),
          ),
          child: child!,
        );
      },
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.pages,
    );
  }
}
