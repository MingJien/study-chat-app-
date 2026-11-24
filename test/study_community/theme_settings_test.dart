import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_chat_app/features/study_community/study_community.dart';

class _FailingSaveStore implements ThemeModeStore {
  _FailingSaveStore({this.initial});

  final ThemeMode? initial;
  bool shouldFailSave = false;

  @override
  Future<ThemeMode?> loadThemeMode() async => initial;

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    if (shouldFailSave) {
      throw Exception('disk write failed');
    }
  }
}

void main() {
  test('ThemeController loads persisted mode, saves changes, and rolls back on error', () async {
    final store = _FailingSaveStore(initial: ThemeMode.dark);
    final controller = ThemeController(store: store);
    addTearDown(controller.dispose);

    expect(controller.themeMode, ThemeMode.system);
    expect(controller.isLoaded, isFalse);

    await controller.load();
    expect(controller.themeMode, ThemeMode.dark);
    expect(controller.isLoaded, isTrue);

    expect(await controller.setThemeMode(ThemeMode.light), isTrue);
    expect(controller.themeMode, ThemeMode.light);
    expect(controller.lastError, isNull);

    store.shouldFailSave = true;
    expect(await controller.setThemeMode(ThemeMode.dark), isFalse);
    expect(controller.themeMode, ThemeMode.light);
    expect(controller.lastError, isNotNull);
  });

  testWidgets(
    'T20: SettingsScreen switches System/Light/Dark and updates MaterialApp',
    (tester) async {
      final controller = ThemeController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        ListenableBuilder(
          listenable: controller,
          builder: (context, child) {
            return MaterialApp(
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              themeMode: controller.themeMode,
              home: SettingsScreen(
                themeController: controller,
                currentUserId: 'tv3_uid',
                currentUserProfile: const UserProfile(
                  uid: 'tv3_uid',
                  displayName: 'Nguyễn Minh',
                  avatarId: 'avatar_tv3',
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.system,
      );

      await tester.tap(find.text('Chế độ tối'));
      await tester.pumpAndSettle();
      expect(controller.themeMode, ThemeMode.dark);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );

      await tester.tap(find.text('Chế độ sáng'));
      await tester.pumpAndSettle();
      expect(controller.themeMode, ThemeMode.light);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.light,
      );

      await tester.tap(find.text('Theo hệ thống'));
      await tester.pumpAndSettle();
      expect(controller.themeMode, ThemeMode.system);
    },
  );

  testWidgets(
    'SettingsScreen keeps previous selection and shows SnackBar on save error',
    (tester) async {
      final store = _FailingSaveStore()..shouldFailSave = true;
      final controller = ThemeController(store: store);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            themeController: controller,
            currentUserId: 'tv3_uid',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chế độ tối'));
      await tester.pumpAndSettle();

      expect(controller.themeMode, ThemeMode.system);
      expect(
        find.text('Không thể lưu chế độ giao diện. Vui lòng thử lại.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'SettingsScreen handles profile/signOut callbacks and preview fallbacks',
    (tester) async {
      final controller = ThemeController();
      addTearDown(controller.dispose);

      // Preview fallbacks when callbacks are null
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            themeController: controller,
            currentUserId: 'tv3_uid',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xem hồ sơ'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Bản preview chưa hỗ trợ mở hồ sơ'),
        findsOneWidget,
      );

      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận đăng xuất'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Bản preview chưa hỗ trợ đăng xuất'),
        findsOneWidget,
      );

      // Wired callbacks: cancel signOut does nothing, confirm triggers callback
      final profileCalls = <String>[];
      var signOuts = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            themeController: controller,
            currentUserId: 'tv3_uid',
            onOpenProfile: ({required uid}) async => profileCalls.add(uid),
            onSignOut: () async => signOuts++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xem hồ sơ'));
      await tester.pumpAndSettle();
      expect(profileCalls, ['tv3_uid']);

      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(signOuts, 0);

      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận đăng xuất'));
      await tester.pumpAndSettle();
      expect(signOuts, 1);
    },
  );

  testWidgets('SettingsScreen fits narrow Android viewport with scaled text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = ThemeController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: SettingsScreen(
            themeController: controller,
            currentUserId: 'tv3_uid',
            currentUserProfile: const UserProfile(
              uid: 'tv3_uid',
              displayName: 'Nguyễn Minh Hiếu Sinh Viên Tên Rất Dài',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
