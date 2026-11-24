import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_chat_app/features/study_community/study_community.dart';

// Controlled failures happen before repository mutation, like a failed write.
class ControlledRepository extends RoomRepository {
  Completer<void>? pending;
  bool failJoin = false;
  bool failLeave = false;
  int joins = 0;
  int leaves = 0;

  @override
  Future<void> joinRoom(String roomId, {required String currentUserId}) async {
    joins++;
    await pending?.future;
    if (failJoin) throw Exception('write failed');
    await super.joinRoom(roomId, currentUserId: currentUserId);
  }

  @override
  Future<void> leaveRoom(String roomId, {required String currentUserId}) async {
    leaves++;
    await pending?.future;
    if (failLeave) throw Exception('write failed');
    await super.leaveRoom(roomId, currentUserId: currentUserId);
  }
}

void main() {
  late ControlledRepository repository;
  late StudyRoom room;
  setUp(() {
    repository = ControlledRepository();
    room = repository.createRoom(
      roomName: 'Mobile',
      subject: 'Flutter',
      description: 'Mô tả phòng',
      ownerId: 'owner',
    );
  });
  tearDown(() => repository.dispose());

  Widget detail({String uid = 'member', OpenRoomDiscussion? open}) =>
      MaterialApp(
        home: RoomDetailScreen(
          room: room,
          repository: repository,
          currentUserId: uid,
          onOpenDiscussion: open,
        ),
      );

  testWidgets(
    'joins once, updates count, confirms/cancels leave and loses chat',
    (tester) async {
      var opens = 0;
      await tester.pumpWidget(
        detail(
          open: ({required roomId, required type}) async {
            expect(roomId, room.roomId);
            expect(type, 'group');
            opens++;
          },
        ),
      );
      expect(find.text('Mô tả phòng'), findsOneWidget);
      expect(find.text('1 thành viên'), findsOneWidget);
      expect(find.text('Vào thảo luận'), findsNothing);
      repository.pending = Completer<void>();
      await tester.tap(find.text('Tham gia phòng'));
      await tester.pump();
      await tester.tap(find.text('Tham gia phòng'));
      expect(repository.joins, 1);
      expect(find.text('Đang xử lý...'), findsOneWidget);
      repository.pending!.complete();
      repository.pending = null;
      await tester.pumpAndSettle();
      expect(find.text('2 thành viên'), findsOneWidget);
      expect(find.text('Đã tham gia'), findsOneWidget);
      await tester.tap(find.text('Vào thảo luận'));
      await tester.pumpAndSettle();
      expect(opens, 1);

      await tester.tap(find.text('Rời phòng'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(repository.leaves, 0);
      await tester.tap(find.text('Rời phòng'));
      await tester.pumpAndSettle();
      repository.pending = Completer<void>();
      await tester.tap(find.text('Xác nhận rời phòng'));
      await tester.pump();
      expect(find.text('Đang xử lý...'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Vào thảo luận'),
            )
            .onPressed,
        isNull,
      );
      repository.pending!.complete();
      repository.pending = null;
      await tester.pumpAndSettle();
      expect(repository.leaves, 1);
      expect(find.text('1 thành viên'), findsOneWidget);
      expect(find.text('Vào thảo luận'), findsNothing);
      expect(find.text('Tham gia phòng'), findsOneWidget);
      expect(opens, 1);
    },
  );

  testWidgets('join/leave updates list labels on return', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RoomsScreen(repository: repository, currentUserId: 'member'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mobile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tham gia phòng'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Đã tham gia'), findsOneWidget);
    await tester.tap(find.text('Mobile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rời phòng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận rời phòng'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Đã tham gia'), findsNothing);
  });

  testWidgets('owner has chat, no leave, and preview explains missing TV2', (
    tester,
  ) async {
    await tester.pumpWidget(detail(uid: 'owner'));
    expect(find.text('Bạn là chủ phòng'), findsOneWidget);
    expect(find.text('Rời phòng'), findsNothing);
    expect(find.text('Tham gia phòng'), findsNothing);
    await tester.tap(find.text('Vào thảo luận'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Bản preview chưa hỗ trợ mở chat'),
      findsOneWidget,
    );
  });

  testWidgets('failures preserve membership, unlock actions and allow retry', (
    tester,
  ) async {
    await tester.pumpWidget(detail());
    repository.failJoin = true;
    await tester.tap(find.text('Tham gia phòng'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Vui lòng thử lại'), findsOneWidget);
    expect(find.text('1 thành viên'), findsOneWidget);
    repository.failJoin = false;
    await tester.tap(find.text('Tham gia phòng'));
    await tester.pumpAndSettle();
    expect(find.text('2 thành viên'), findsOneWidget);
    repository.failLeave = true;
    await tester.tap(find.text('Rời phòng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận rời phòng'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Vui lòng thử lại'), findsOneWidget);
    expect(find.text('2 thành viên'), findsOneWidget);
    expect(find.text('Vào thảo luận'), findsOneWidget);
    repository.failLeave = false;
    await tester.tap(find.text('Rời phòng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận rời phòng'));
    await tester.pumpAndSettle();
    expect(find.text('1 thành viên'), findsOneWidget);
  });

  testWidgets(
    'rechecks membership even before UI rebuild after external leave',
    (tester) async {
      await repository.joinRoom(room.roomId, currentUserId: 'member');
      var opens = 0;
      await tester.pumpWidget(
        detail(
          open: ({required roomId, required type}) async {
            opens++;
          },
        ),
      );
      final staleAction = tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Vào thảo luận'),
          )
          .onPressed!;
      await repository.leaveRoom(room.roomId, currentUserId: 'member');
      staleAction();
      await tester.pumpAndSettle();
      expect(opens, 0);
      expect(find.textContaining('Bạn cần tham gia phòng'), findsOneWidget);
      expect(find.text('Tham gia phòng'), findsOneWidget);
      expect(find.text('Vào thảo luận'), findsNothing);
    },
  );

  testWidgets('unknown room is stable with no actions', (tester) async {
    final empty = RoomRepository();
    addTearDown(empty.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: RoomDetailScreen(
          room: room,
          repository: empty,
          currentUserId: 'member',
        ),
      ),
    );
    expect(find.text('Phòng không còn tồn tại.'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'chat callback propagates through list and creation for active UID',
    (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: RoomsScreen(
            repository: repository,
            currentUserId: 'custom_uid',
            onOpenDiscussion: ({required roomId, required type}) async {
              calls.add('$roomId:$type');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mobile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tham gia phòng'));
      await tester.pumpAndSettle();
      expect(repository.memberOf(room.roomId, 'custom_uid'), isNotNull);
      await tester.tap(find.text('Vào thảo luận'));
      await tester.pumpAndSettle();
      expect(calls, ['${room.roomId}:group']);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tạo phòng'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Phòng mới');
      await tester.tap(find.widgetWithText(FilledButton, 'Tạo phòng'));
      await tester.pumpAndSettle();
      expect(find.text('Bạn là chủ phòng'), findsOneWidget);
      await tester.tap(find.text('Vào thảo luận'));
      await tester.pumpAndSettle();
      expect(calls.last, '${repository.rooms.first.roomId}:group');
      expect(repository.rooms.first.ownerId, 'custom_uid');
    },
  );

  testWidgets('detail fits narrow Android with long content and scaled text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final longRoom = repository.createRoom(
      roomName: 'Tên phòng học rất dài ' * 3,
      subject: 'Flutter ' * 10,
      description: 'Mô tả ' * 50,
      ownerId: 'owner',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: RoomDetailScreen(
            room: longRoom,
            repository: repository,
            currentUserId: 'member',
          ),
        ),
      ),
    );
    await tester.scrollUntilVisible(find.text('Tham gia phòng'), 200);
    expect(tester.takeException(), isNull);
  });
}
