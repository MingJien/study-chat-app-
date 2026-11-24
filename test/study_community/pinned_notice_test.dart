import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_chat_app/features/study_community/study_community.dart';

class _ControlledNoticeRepository extends RoomRepository {
  _ControlledNoticeRepository({super.profiles});

  Completer<void>? pending;
  bool failNoticeWrite = false;
  int writes = 0;

  @override
  Future<void> updatePinnedNotice(
    String roomId, {
    required String currentUserId,
    required String content,
  }) async {
    writes++;
    await pending?.future;
    if (failNoticeWrite) {
      throw Exception('notice write failed');
    }
    await super.updatePinnedNotice(
      roomId,
      currentUserId: currentUserId,
      content: content,
    );
  }
}

void main() {
  late RoomRepository repository;
  late StudyRoom room;

  setUp(() async {
    repository = RoomRepository(
      profiles: const {
        'owner_uid': UserProfile(uid: 'owner_uid', displayName: 'Chủ phòng A'),
        'member_uid': UserProfile(
          uid: 'member_uid',
          displayName: 'Thành viên B',
        ),
        'outsider_uid': UserProfile(
          uid: 'outsider_uid',
          displayName: 'Người ngoài C',
        ),
      },
    );
    room = repository.createRoom(
      roomName: 'Mobile',
      subject: 'Flutter',
      description: 'Thảo luận nhóm',
      ownerId: 'owner_uid',
    );
    await repository.joinRoom(room.roomId, currentUserId: 'member_uid');
  });

  tearDown(() => repository.dispose());

  test('T17: owner pins, edits, clears notice and watchPinnedNotice streams updates', () async {
    final snapshots = <String?>[];
    final sub = repository.watchPinnedNotice(room.roomId).listen((notice) {
      snapshots.add(notice?.content);
    });

    await Future<void>.delayed(Duration.zero);
    await repository.updatePinnedNotice(
      room.roomId,
      currentUserId: 'owner_uid',
      content: '  Hạn nộp bài: Thứ Sáu  ',
    );
    expect(
      repository.pinnedNoticeOf(room.roomId)?.content,
      'Hạn nộp bài: Thứ Sáu',
    );
    expect(repository.pinnedNoticeOf(room.roomId)?.updatedBy, 'owner_uid');

    await repository.updatePinnedNotice(
      room.roomId,
      currentUserId: 'owner_uid',
      content: 'Đổi hạn nộp: Thứ Bảy',
    );
    expect(
      repository.pinnedNoticeOf(room.roomId)?.content,
      'Đổi hạn nộp: Thứ Bảy',
    );

    await repository.clearPinnedNotice(room.roomId, currentUserId: 'owner_uid');
    expect(repository.pinnedNoticeOf(room.roomId), isNull);

    expect(snapshots, [
      null,
      'Hạn nộp bài: Thứ Sáu',
      'Đổi hạn nộp: Thứ Bảy',
      null,
    ]);

    await sub.cancel();
    await repository.updatePinnedNotice(
      room.roomId,
      currentUserId: 'owner_uid',
      content: 'Sau khi hủy stream',
    );
    await Future<void>.delayed(Duration.zero);
    expect(snapshots.length, 4);
  });

  test(
    'T18: member and non-member cannot edit or clear pinned notice',
    () async {
      await repository.updatePinnedNotice(
        room.roomId,
        currentUserId: 'owner_uid',
        content: 'Thông báo gốc',
      );

      for (final uid in ['member_uid', 'outsider_uid']) {
        await expectLater(
          repository.updatePinnedNotice(
            room.roomId,
            currentUserId: uid,
            content: 'Nội dung trái phép',
          ),
          throwsA(isA<RoomNoticeException>()),
        );
        await expectLater(
          repository.clearPinnedNotice(room.roomId, currentUserId: uid),
          throwsA(isA<RoomNoticeException>()),
        );
      }

      expect(repository.pinnedNoticeOf(room.roomId)?.content, 'Thông báo gốc');
    },
  );

  test(
    'validates 300 grapheme character limit, missing room, and blank UID',
    () async {
      final valid300 = 'e\u0301' * 300;
      await repository.updatePinnedNotice(
        room.roomId,
        currentUserId: 'owner_uid',
        content: '  $valid300  ',
      );
      expect(repository.pinnedNoticeOf(room.roomId)?.content, valid300);

      final invalid301 = 'e\u0301' * 301;
      await expectLater(
        repository.updatePinnedNotice(
          room.roomId,
          currentUserId: 'owner_uid',
          content: invalid301,
        ),
        throwsA(isA<RoomNoticeException>()),
      );
      expect(repository.pinnedNoticeOf(room.roomId)?.content, valid300);

      await expectLater(
        repository.updatePinnedNotice(
          'missing_room',
          currentUserId: 'owner_uid',
          content: 'Hợp lệ',
        ),
        throwsA(isA<RoomNoticeException>()),
      );
      await expectLater(
        repository.updatePinnedNotice(
          room.roomId,
          currentUserId: ' ',
          content: 'Hợp lệ',
        ),
        throwsA(isA<RoomNoticeException>()),
      );
    },
  );

  testWidgets(
    'owner pins with validation, edits, cancels unpin, and confirms unpin',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RoomDetailScreen(
            room: room,
            repository: repository,
            currentUserId: 'owner_uid',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ghim thông báo'), findsOneWidget);
      expect(find.byType(PinnedNoticeBanner), findsNothing);

      await tester.tap(find.text('Ghim thông báo'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '   ');
      await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập nội dung thông báo.'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'a' * 301);
      await tester.pumpAndSettle();
      expect(find.text('Thông báo ghim tối đa 300 ký tự.'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField),
        '  Nộp bài trước thứ Sáu  ',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
      await tester.pumpAndSettle();

      expect(find.byType(PinnedNoticeBanner), findsOneWidget);
      expect(find.text('Nộp bài trước thứ Sáu'), findsOneWidget);
      expect(find.text('Cập nhật bởi Chủ phòng A'), findsOneWidget);
      expect(find.text('Sửa ghim'), findsOneWidget);
      expect(find.text('Bỏ ghim'), findsOneWidget);

      await tester.tap(find.text('Sửa ghim'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField),
        'Lịch thi dời sang thứ Hai',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Lịch thi dời sang thứ Hai'), findsOneWidget);

      await tester.tap(find.text('Bỏ ghim'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(find.text('Lịch thi dời sang thứ Hai'), findsOneWidget);

      await tester.tap(find.text('Bỏ ghim'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận bỏ ghim'));
      await tester.pumpAndSettle();
      expect(find.byType(PinnedNoticeBanner), findsNothing);
      expect(find.text('Ghim thông báo'), findsOneWidget);
    },
  );

  testWidgets(
    'member sees read-only notice; non-member sees notice only after joining',
    (tester) async {
      await repository.updatePinnedNotice(
        room.roomId,
        currentUserId: 'owner_uid',
        content: 'Thông báo chỉ dành cho thành viên',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RoomDetailScreen(
            room: room,
            repository: repository,
            currentUserId: 'member_uid',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PinnedNoticeBanner), findsOneWidget);
      expect(find.text('Thông báo chỉ dành cho thành viên'), findsOneWidget);
      expect(find.text('Ghim thông báo'), findsNothing);
      expect(find.text('Sửa ghim'), findsNothing);
      expect(find.text('Bỏ ghim'), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          home: RoomDetailScreen(
            room: room,
            repository: repository,
            currentUserId: 'outsider_uid',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PinnedNoticeBanner), findsNothing);
      expect(find.text('Thông báo chỉ dành cho thành viên'), findsNothing);

      await tester.tap(find.text('Tham gia phòng'));
      await tester.pumpAndSettle();
      expect(find.byType(PinnedNoticeBanner), findsOneWidget);
      expect(find.text('Thông báo chỉ dành cho thành viên'), findsOneWidget);
    },
  );

  testWidgets(
    'reusable PinnedNoticeBanner for TV2 updates live on pin, edit, and clear',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinnedNoticeBanner(
              roomId: room.roomId,
              repository: repository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Thông báo ghim'), findsNothing);

      await repository.updatePinnedNotice(
        room.roomId,
        currentUserId: 'owner_uid',
        content: 'Tin ghim đầu tiên',
      );
      await tester.pumpAndSettle();
      expect(find.text('Thông báo ghim'), findsOneWidget);
      expect(find.text('Tin ghim đầu tiên'), findsOneWidget);

      await repository.updatePinnedNotice(
        room.roomId,
        currentUserId: 'owner_uid',
        content: 'Tin ghim cập nhật',
      );
      await tester.pumpAndSettle();
      expect(find.text('Tin ghim cập nhật'), findsOneWidget);

      await repository.clearPinnedNotice(
        room.roomId,
        currentUserId: 'owner_uid',
      );
      await tester.pumpAndSettle();
      expect(find.text('Thông báo ghim'), findsNothing);
    },
  );

  testWidgets(
    'async failure preserves existing notice, unlocks actions, and retries',
    (tester) async {
      final controlled = _ControlledNoticeRepository(
        profiles: const {
          'owner_uid': UserProfile(
            uid: 'owner_uid',
            displayName: 'Chủ phòng A',
          ),
        },
      );
      addTearDown(controlled.dispose);
      final controlledRoom = controlled.createRoom(
        roomName: 'Mobile',
        subject: 'Flutter',
        description: 'Mô tả',
        ownerId: 'owner_uid',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RoomDetailScreen(
            room: controlledRoom,
            repository: controlled,
            currentUserId: 'owner_uid',
          ),
        ),
      );
      await tester.pumpAndSettle();

      controlled.failNoticeWrite = true;
      await tester.tap(find.text('Ghim thông báo'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Nội dung lỗi');
      await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
      await tester.pumpAndSettle();

      expect(
        find.text('Không thể thực hiện thao tác. Vui lòng thử lại.'),
        findsOneWidget,
      );
      expect(controlled.pinnedNoticeOf(controlledRoom.roomId), isNull);

      controlled.failNoticeWrite = false;
      await tester.tap(find.text('Ghim thông báo'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Nội dung thành công');
      await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
      await tester.pumpAndSettle();

      expect(find.text('Nội dung thành công'), findsOneWidget);
    },
  );

  testWidgets(
    '300-char pinned notice fits narrow Android viewport with scaled text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final longNotice = 'Thông báo quan trọng cần đọc kỹ. ' * 10;
      await repository.updatePinnedNotice(
        room.roomId,
        currentUserId: 'owner_uid',
        content: longNotice.substring(0, 300),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: RoomDetailScreen(
              room: room,
              repository: repository,
              currentUserId: 'owner_uid',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(PinnedNoticeBanner), findsOneWidget);
    },
  );
}
