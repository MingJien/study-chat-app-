import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../features/realtime_chat/data/cache_factory.dart';
import '../features/realtime_chat/data/chat_cache.dart';
import '../features/realtime_chat/data/chat_repository.dart';
import '../features/realtime_chat/data/chat_rest.dart';
import '../features/realtime_chat/presentation/chat_widgets.dart';
import 'app_router.dart';
import 'app_theme.dart';
import 'session_form.dart';

class StudyChatApp extends StatefulWidget {
  const StudyChatApp({
    super.key,
    required this.auth,
    required this.db,
    required this.endpoint,
  });
  final FirebaseAuth auth;
  final FirebaseDatabase db;
  final Uri endpoint;
  @override
  State<StudyChatApp> createState() => _StudyChatAppState();
}

class _StudyChatAppState extends State<StudyChatApp> {
  ThemeMode mode = ThemeMode.system;
  late final sessions = widget.auth.authStateChanges();
  final prefs = SharedPreferencesAsync();
  @override
  void initState() {
    super.initState();
    prefs.getBool('study-chat-dark').then((dark) {
      if (mounted && dark != null) {
        setState(() => mode = dark ? ThemeMode.dark : ThemeMode.light);
      }
    });
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Study Chat',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: mode,
    builder: (context, child) =>
        kIsWeb &&
            const bool.fromEnvironment('FIREBASE_EMULATOR', defaultValue: true)
        ? ColoredBox(
            color: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: child,
            ),
          )
        : child!,
    home: StreamBuilder(
      stream: sessions,
      builder: (context, s) {
        if (s.hasError) {
          return Scaffold(body: StatePanel(readableError(s.error)));
        }
        if (s.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = s.data == null ? null : widget.auth.currentUser;
        if (user == null) return SessionForm(widget.auth, widget.db);
        if ((user.displayName ?? '').isEmpty) {
          return SessionForm(
            widget.auth,
            widget.db,
            key: ValueKey(user.uid),
            user: user,
            onProfile: () => setState(() {}),
          );
        }
        return _Session(
          key: ValueKey(user.uid),
          auth: widget.auth,
          db: widget.db,
          endpoint: widget.endpoint,
          uid: user.uid,
          changeTheme: () {
            final dark = Theme.of(context).brightness != Brightness.dark;
            setState(() => mode = dark ? ThemeMode.dark : ThemeMode.light);
            prefs.setBool('study-chat-dark', dark);
          },
        );
      },
    ),
  );
}

class _Session extends StatefulWidget {
  const _Session({
    super.key,
    required this.uid,
    required this.auth,
    required this.db,
    required this.endpoint,
    required this.changeTheme,
  });
  final String uid;
  final FirebaseAuth auth;
  final FirebaseDatabase db;
  final Uri endpoint;
  final VoidCallback changeTheme;
  @override
  State<_Session> createState() => _SessionState();
}

class _SessionState extends State<_Session> {
  late final repo = ChatRepository(
    widget.uid,
    widget.auth,
    widget.db,
    ChatCache(chatDatabaseFactory),
    ChatRest(widget.auth, widget.endpoint, http.Client()),
  );
  late final StreamSubscription<Object> errors;
  @override
  void initState() {
    super.initState();
    errors = repo.errors.listen((e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(readableError(e))));
      }
    });
  }

  Future<void> logout() async {
    try {
      await repo.close();
    } finally {
      await widget.auth.signOut();
    }
  }

  @override
  void dispose() {
    errors.cancel();
    unawaited(repo.close().catchError((_) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Navigator(
    onGenerateRoute: AppRouter(repo, widget.changeTheme, logout).route,
  );
}
