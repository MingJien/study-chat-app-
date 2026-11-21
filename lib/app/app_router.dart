import 'package:flutter/material.dart';

import 'app_shell.dart';

/// TV3 adds business routes after agreeing arguments with TV1 and TV2.
abstract final class AppRouter {
  static Map<String, WidgetBuilder> get routes => {
    '/': (context) => const AppShell(),
  };
}
