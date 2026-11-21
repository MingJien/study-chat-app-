import 'package:flutter/material.dart';

import 'app_router.dart';
import 'app_theme.dart';

class StudyChatApp extends StatelessWidget {
  const StudyChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Chat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      initialRoute: '/',
      routes: AppRouter.routes,
    );
  }
}
