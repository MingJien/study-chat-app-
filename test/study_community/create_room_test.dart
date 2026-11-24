import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_chat_app/features/study_community/study_community.dart';

Widget _previewApp(RoomRepository repository) {
  return MaterialApp(
    home: RoomsScreen(repository: repository, currentUserId: tv3PreviewUserId),
  );
}

void main() {
  testWidgets('Creates Mobile, shows its owner, and returns to updated list', (
    tester,
  ) async {
    final repository = RoomRepository();
    addTearDown(repository.dispose);
    await tester.pumpWidget(_previewApp(repository));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có phòng học'), findsOneWidget);

    await tester.tap(find.text('Tạo phòng'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '  Mobile  ');
    await tester.enterText(fields.at(1), 'Lập trình di động');
    await tester.enterText(fields.at(2), 'Trao đổi bài tập');
    await tester.tap(find.widgetWithText(FilledButton, 'Tạo phòng'));
    await tester.pumpAndSettle();

    expect(find.text('Chi tiết phòng'), findsOneWidget);
    expect(find.text('Mobile'), findsOneWidget);
    expect(find.text('Lập trình di động'), findsOneWidget);
    expect(find.text('Trao đổi bài tập'), findsOneWidget);
    expect(find.text('Chủ phòng'), findsOneWidget);
    final created = tester.widget<RoomDetailScreen>(
      find.byType(RoomDetailScreen),
    );
    expect(created.room.roomId, startsWith('room_'));
    expect(created.creator?.uid, created.room.ownerId);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Khám phá phòng'), findsOneWidget);
    expect(find.text('Chưa có phòng học'), findsNothing);
    expect(find.text('Mobile'), findsOneWidget);

    await tester.tap(find.text('Mobile'));
    await tester.pumpAndSettle();
    final reopened = tester.widget<RoomDetailScreen>(
      find.byType(RoomDetailScreen),
    );
    expect(reopened.room.roomId, created.room.roomId);
    expect(find.text('Chủ phòng'), findsOneWidget);
  });

  testWidgets('Shows inline errors and accepts values at the exact limits', (
    tester,
  ) async {
    final repository = RoomRepository();
    addTearDown(repository.dispose);
    await tester.pumpWidget(_previewApp(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạo phòng'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    final submit = find.widgetWithText(FilledButton, 'Tạo phòng');

    await tester.enterText(fields.at(0), '   ');
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Nhập tên phòng.'), findsOneWidget);
    expect(find.byType(RoomDetailScreen), findsNothing);

    await tester.enterText(fields.at(0), 'a' * 61);
    await tester.enterText(fields.at(1), 'b' * 61);
    await tester.enterText(fields.at(2), 'c' * 201);
    await tester.pumpAndSettle();
    expect(find.text('Tên phòng tối đa 60 ký tự.'), findsOneWidget);
    expect(find.text('Môn học tối đa 60 ký tự.'), findsOneWidget);
    expect(find.text('Mô tả tối đa 200 ký tự.'), findsOneWidget);

    final validName = 'e\u0301' * 60;
    await tester.enterText(fields.at(0), '  $validName  ');
    await tester.enterText(fields.at(1), 'b' * 60);
    await tester.enterText(fields.at(2), 'c' * 200);
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.byType(RoomDetailScreen), findsOneWidget);
    expect(find.text(validName), findsOneWidget);
  });

  testWidgets('keeps the active search applied to a newly created room', (
    tester,
  ) async {
    const ownerId = tv3PreviewUserId;
    final repository = RoomRepository(
      initialRooms: [
        StudyRoom(
          roomId: 'room_existing',
          roomName: 'Mobile căn bản',
          subject: 'Flutter',
          description: 'Phòng có sẵn',
          ownerId: ownerId,
          createdAt: DateTime.utc(2026, 11, 21),
        ),
      ],
      initialMembers: const {
        'room_existing': [RoomMember(uid: ownerId, role: RoomRole.owner)],
      },
      profiles: const {
        ownerId: UserProfile(uid: ownerId, displayName: 'Bạn (TV3)'),
      },
    );
    addTearDown(repository.dispose);
    await tester.pumpWidget(_previewApp(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), ' mobile ');
    await tester.tap(find.widgetWithText(FilledButton, 'Tạo phòng'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Mobile nâng cao');
    await tester.tap(find.widgetWithText(FilledButton, 'Tạo phòng'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Mobile nâng cao'), findsOneWidget);
    expect(find.text('Mobile căn bản'), findsOneWidget);
    expect(find.text('Không tìm thấy phòng phù hợp'), findsNothing);
  });

  test('Stores an owner record per room and permits duplicate names', () {
    final repository = RoomRepository();
    addTearDown(repository.dispose);
    const ownerId = 'test_owner';

    StudyRoom create() => repository.createRoom(
      roomName: 'Mobile',
      subject: '',
      description: '',
      ownerId: ownerId,
    );

    final first = create();
    final second = create();
    expect(repository.rooms, [second, first]);
    expect(first.roomName, second.roomName);
    expect(first.roomId, startsWith('room_'));
    expect(second.roomId, startsWith('room_'));
    expect(first.roomId, isNot(second.roomId));
    for (final room in repository.rooms) {
      final member = repository.memberOf(room.roomId, ownerId);
      expect(member?.role, RoomRole.owner);
      expect(member?.uid, room.ownerId);
    }
  });
}
