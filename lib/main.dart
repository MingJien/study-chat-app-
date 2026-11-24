import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) SemanticsBinding.instance.ensureSemantics();
  const project = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'demo-classroom-tv2',
  );
  const emulator = bool.fromEnvironment(
    'FIREBASE_EMULATOR',
    defaultValue: true,
  );
  const databaseUrl = String.fromEnvironment(
    'FIREBASE_DATABASE_URL',
    defaultValue: 'https://$project-default-rtdb.firebaseio.com',
  );
  final host = kIsWeb
      ? '127.0.0.1'
      : const String.fromEnvironment('EMULATOR_HOST', defaultValue: '10.0.2.2');
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        projectId: project,
        apiKey: String.fromEnvironment(
          'FIREBASE_API_KEY',
          defaultValue: 'demo-key',
        ),
        appId: String.fromEnvironment(
          'FIREBASE_APP_ID',
          defaultValue: '1:1234567890:web:0123456789abcdef',
        ),
        messagingSenderId: String.fromEnvironment(
          'FIREBASE_SENDER_ID',
          defaultValue: '1234567890',
        ),
        databaseURL: databaseUrl,
        authDomain: '$project.firebaseapp.com',
      ),
    );
    final auth = FirebaseAuth.instance;
    final db = FirebaseDatabase.instance;
    if (emulator) {
      await auth.useAuthEmulator(host, 9099, automaticHostMapping: false);
      db.useDatabaseEmulator(host, 9000, automaticHostMapping: false);
    }
    final endpoint = emulator
        ? Uri.http('$host:9000', '', {'ns': '$project-default-rtdb'})
        : Uri.parse(databaseUrl);
    runApp(StudyChatApp(auth: auth, db: db, endpoint: endpoint));
  } catch (_) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Chưa khởi tạo được Firebase. Kiểm tra cấu hình và tải lại trang.',
            ),
          ),
        ),
      ),
    );
  }
}
