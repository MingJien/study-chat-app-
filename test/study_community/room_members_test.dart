import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_chat_app/features/study_community/study_community.dart';

void main() {
  late RoomRepository repository;
  late StudyRoom room;

  setUp(() {
    repository = RoomRepository(
      profiles: const {
        'owner_uid': UserProfile(
          uid: 'owner_uid',
          displayName: 'Trần Minh',
          avatarId: 'avatar_tv3',
        ),
        'an_uid': UserProfile(
          uid: 'an_uid',
          displayName: 'Nguyễn An',
          avatarId: 'avatar_linh',
        ),
        'binh_uid': UserProfile(
          uid: 'binh_uid',
          displayName: 'Lê Bình',
          avatarId: 'avatar_minh',
        ),
      },
    );
    room = repository.createRoom(
      roomName: 'Lập trình Mobile',
      subject: 'Flutter',
      description: 'Thảo luận TV3-05',
      ownerId: 'owner_uid',
    );
  });

  tearDown(() => repository.dispose());

  test(
    'membersOf returns owner first, sorts members, handles missing room',
    () async {
      await repository.joinRoom(room.roomId, currentUserId: 'an_uid');
      await repository.joinRoom(room.roomId, currentUserId: 'binh_uid');

      final members = repository.membersOf(room.roomId);
      expect(members.map((m) => m.uid), ['owner_uid', 'binh_uid', 'an_uid']);
      expect(members.first.role, RoomRole.owner);
      expect(members[1].role, RoomRole.member);
      expect(members[2].role, RoomRole.member);
      expect(repository.membersOf('missing_room'), isEmpty);
    },
  );

  test('watchRoomMembers emits initial list, join/leave updates, and stops on cancel', () async {
    final snapshots = <List<String>>[];
    final sub = repository.watchRoomMembers(room.roomId).listen((members) {
      snapshots.add(members.map((m) => m.uid).toList());
    });

    await Future<void>.delayed(Duration.zero);
    await repository.joinRoom(room.roomId, currentUserId: 'an_uid');
    await repository.leaveRoom(room.roomId, currentUserId: 'an_uid');

    expect(snapshots, [
      ['owner_uid'],
      ['owner_uid', 'an_uid'],
      ['owner_uid'],
    ]);

    await sub.cancel();
    await repository.joinRoom(room.roomId, currentUserId: 'binh_uid');
    await Future<void>.delayed(Duration.zero);
    expect(snapshots.length, 3);
  });

  testWidgets(
    'displays member names, avatars, roles and hides Nhắn tin on self',
    (tester) async {
      await repository.joinRoom(room.roomId, currentUserId: 'an_uid');

      await tester.pumpWidget(
        MaterialApp(
          home: RoomMembersScreen(
            room: room,
            repository: repository,
            currentUserId: 'an_uid',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thành viên phòng'), findsOneWidget);
      expect(find.text('2 thành viên'), findsOneWidget);
      expect(find.text('Trần Minh'), findsOneWidget);
      expect(find.text('Nguyễn An (Bạn)'), findsOneWidget);
      expect(find.text('Chủ phòng'), findsOneWidget);
      expect(find.text('Thành viên'), findsOneWidget);

      final avatars = tester.widgetList<MemberAvatar>(
        find.byType(MemberAvatar),
      );
      expect(avatars.map((a) => a.avatarId), ['avatar_tv3', 'avatar_linh']);

      // Only one "Nhắn tin" button (for owner_uid, hidden on self an_uid).
      expect(find.widgetWithText(OutlinedButton, 'Nhắn tin'), findsOneWidget);
    },
  );

  testWidgets('updates live when a member joins or leaves', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RoomMembersScreen(
          room: room,
          repository: repository,
          currentUserId: 'owner_uid',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 thành viên'), findsOneWidget);
    expect(find.text('Nguyễn An'), findsNothing);

    await repository.joinRoom(room.roomId, currentUserId: 'an_uid');
    await tester.pumpAndSettle();
    expect(find.text('2 thành viên'), findsOneWidget);
    expect(find.text('Nguyễn An'), findsOneWidget);

    await repository.leaveRoom(room.roomId, currentUserId: 'an_uid');
    await tester.pumpAndSettle();
    expect(find.text('1 thành viên'), findsOneWidget);
    expect(find.text('Nguyễn An'), findsNothing);
  });

  testWidgets(
    'opens from RoomDetailScreen and propagates profile & DM callbacks across RoomsScreen and CreateRoomScreen',
    (tester) async {
      await repository.joinRoom(room.roomId, currentUserId: 'an_uid');
      final profileCalls = <String>[];
      final dmCalls = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: RoomsScreen(
            repository: repository,
            currentUserId: 'an_uid',
            onOpenProfile: ({required uid}) async => profileCalls.add(uid),
            onOpenDirectMessage: ({required peerUid}) async =>
                dmCalls.add(peerUid),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Flow 1: RoomsScreen -> RoomDetailScreen -> RoomMembersScreen
      await tester.tap(find.text('Lập trình Mobile'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Xem thành viên'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Trần Minh'));
      await tester.pumpAndSettle();
      expect(profileCalls, ['owner_uid']);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Nhắn tin'));
      await tester.pumpAndSettle();
      expect(dmCalls, ['owner_uid']);

      // Flow 2: back to RoomsScreen -> CreateRoomScreen -> RoomDetailScreen -> RoomMembersScreen
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Tạo phòng'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Phòng Mới');
      await tester.tap(find.widgetWithText(FilledButton, 'Tạo phòng'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Xem thành viên'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nguyễn An (Bạn)'));
      await tester.pumpAndSettle();
      expect(profileCalls, ['owner_uid', 'an_uid']);
    },
  );

  testWidgets(
    'shows preview SnackBars when callbacks are null and handles async callback errors cleanly',
    (tester) async {
      await repository.joinRoom(room.roomId, currentUserId: 'an_uid');

      // Missing callbacks -> preview guidance SnackBars
      await tester.pumpWidget(
        MaterialApp(
          home: RoomMembersScreen(
            room: room,
            repository: repository,
            currentUserId: 'an_uid',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Trần Minh'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Bản preview chưa hỗ trợ mở hồ sơ'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Nhắn tin'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Bản preview chưa hỗ trợ nhắn tin riêng'),
        findsOneWidget,
      );

      // Failing callbacks -> friendly error and unlocks buttons
      final completer = Completer<void>();
      var fail = true;
      var attempts = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: RoomMembersScreen(
            room: room,
            repository: repository,
            currentUserId: 'an_uid',
            onOpenProfile: ({required uid}) async {
              attempts++;
              await completer.future;
              if (fail) throw Exception('tv1 unavailable');
            },
            onOpenDirectMessage: ({required peerUid}) async {
              throw Exception('tv2 unavailable');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Trần Minh'));
      await tester.pump();
      // While busy, second tap is ignored
      await tester.tap(find.text('Trần Minh'));
      expect(attempts, 1);

      completer.complete();
      await tester.pumpAndSettle();
      expect(
        find.text('Không thể thực hiện thao tác. Vui lòng thử lại.'),
        findsOneWidget,
      );

      // Retry succeeds after fail clears
      fail = false;
      await tester.tap(find.text('Trần Minh'));
      await tester.pumpAndSettle();
      expect(attempts, 2);

      // Direct message error SnackBar
      await tester.tap(find.widgetWithText(OutlinedButton, 'Nhắn tin'));
      await tester.pumpAndSettle();
      expect(
        find.text('Không thể thực hiện thao tác. Vui lòng thử lại.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('missing room renders fallback message safely', (tester) async {
    final empty = RoomRepository();
    addTearDown(empty.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: RoomMembersScreen(
          room: room,
          repository: empty,
          currentUserId: 'an_uid',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Phòng không còn tồn tại.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits narrow Android viewport with scaled text and long names', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final longRepo = RoomRepository(
      profiles: const {
        'long_owner': UserProfile(
          uid: 'long_owner',
          displayName: 'Nguyễn Hoàng Phương Anh Thảo Minh Châu Rất Dài',
          avatarId: 'avatar_1',
        ),
        'long_member': UserProfile(
          uid: 'long_member',
          displayName: 'Trần Bảo Quốc Khánh Duy Nam Bình An Rất Dài',
          avatarId: 'avatar_2',
        ),
      },
    );
    addTearDown(longRepo.dispose);

    final longRoom = longRepo.createRoom(
      roomName: 'Phòng học có tên rất dài trên màn hình nhỏ ' * 2,
      subject: 'Mobile',
      description: '',
      ownerId: 'long_owner',
    );
    await longRepo.joinRoom(longRoom.roomId, currentUserId: 'long_member');

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: RoomMembersScreen(
            room: longRoom,
            repository: longRepo,
            currentUserId: 'long_member',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(OutlinedButton, 'Nhắn tin'), findsOneWidget);
  });
}
