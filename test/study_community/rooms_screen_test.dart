import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_chat_app/features/study_community/study_community.dart';

const currentUserId = 'current_uid';

StudyRoom room({
  required String id,
  required String name,
  required String subject,
  required String ownerId,
  String description = 'Mô tả phòng học',
}) {
  return StudyRoom(
    roomId: id,
    roomName: name,
    subject: subject,
    description: description,
    ownerId: ownerId,
    createdAt: DateTime.utc(2026, 11, 21),
  );
}

Widget appFor(RoomRepository repository) {
  return MaterialApp(
    home: RoomsScreen(repository: repository, currentUserId: currentUserId),
  );
}

void main() {
  testWidgets('shows creator names and membership labels', (tester) async {
    final repository = RoomRepository(
      initialRooms: [
        room(
          id: 'room_owned',
          name: 'Mobile nâng cao',
          subject: 'Flutter',
          ownerId: currentUserId,
        ),
        room(
          id: 'room_joined',
          name: 'Cơ sở dữ liệu',
          subject: 'SQL',
          ownerId: 'owner_an',
        ),
        room(
          id: 'room_public',
          name: 'Thiết kế web',
          subject: 'Frontend',
          ownerId: 'owner_binh',
        ),
      ],
      initialMembers: {
        'room_owned': [
          const RoomMember(uid: currentUserId, role: RoomRole.owner),
        ],
        'room_joined': [
          const RoomMember(uid: currentUserId, role: RoomRole.member),
        ],
      },
      profiles: const {
        currentUserId: UserProfile(
          uid: currentUserId,
          displayName: 'Bạn (TV3)',
        ),
        'owner_an': UserProfile(uid: 'owner_an', displayName: 'Nguyễn An'),
        'owner_binh': UserProfile(uid: 'owner_binh', displayName: 'Trần Bình'),
      },
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(appFor(repository));
    await tester.pumpAndSettle();

    expect(find.text('Mobile nâng cao'), findsOneWidget);
    expect(find.text('Flutter'), findsOneWidget);
    expect(find.text('Người tạo: Bạn (TV3)'), findsOneWidget);
    expect(find.text('Người tạo: Nguyễn An'), findsOneWidget);
    expect(find.text('Người tạo: Trần Bình'), findsOneWidget);
    expect(find.text('Chủ phòng'), findsOneWidget);
    expect(find.text('Đã tham gia'), findsOneWidget);
  });

  testWidgets('searches by trimmed case-insensitive room name or subject', (
    tester,
  ) async {
    final repository = RoomRepository(
      initialRooms: [
        room(
          id: 'room_mobile',
          name: 'Lập trình Mobile',
          subject: 'Flutter',
          ownerId: 'owner_an',
        ),
        room(
          id: 'room_database',
          name: 'Cơ sở dữ liệu',
          subject: 'SQL nâng cao',
          ownerId: 'owner_an',
        ),
      ],
      profiles: const {
        'owner_an': UserProfile(uid: 'owner_an', displayName: 'Nguyễn An'),
      },
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(appFor(repository));
    await tester.pumpAndSettle();

    final search = find.byType(TextField);
    await tester.enterText(search, '  mObIlE  ');
    await tester.pump();
    expect(find.text('Lập trình Mobile'), findsOneWidget);
    expect(find.text('Cơ sở dữ liệu'), findsNothing);

    await tester.enterText(search, '  sql  ');
    await tester.pump();
    expect(find.text('Lập trình Mobile'), findsNothing);
    expect(find.text('Cơ sở dữ liệu'), findsOneWidget);

    await tester.enterText(search, 'không tồn tại');
    await tester.pump();
    expect(find.text('Không tìm thấy phòng phù hợp'), findsOneWidget);

    await tester.enterText(search, '');
    await tester.pump();
    expect(find.text('Lập trình Mobile'), findsOneWidget);
    expect(find.text('Cơ sở dữ liệu'), findsOneWidget);
  });

  testWidgets('shows loading then an empty state with create action', (
    tester,
  ) async {
    final loadCompleter = Completer<void>();
    final repository = RoomRepository(onLoad: () => loadCompleter.future);
    addTearDown(repository.dispose);

    await tester.pumpWidget(appFor(repository));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    loadCompleter.complete();
    await tester.pumpAndSettle();
    expect(find.text('Chưa có phòng học'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Tạo phòng'), findsOneWidget);
  });

  testWidgets('shows a friendly error and retries loading', (tester) async {
    var attempts = 0;
    final repository = RoomRepository(
      initialRooms: [
        room(
          id: 'room_mobile',
          name: 'Mobile',
          subject: 'Flutter',
          ownerId: 'owner_an',
        ),
      ],
      profiles: const {
        'owner_an': UserProfile(uid: 'owner_an', displayName: 'Nguyễn An'),
      },
      onLoad: () async {
        attempts++;
        if (attempts == 1) throw Exception('network unavailable');
      },
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(appFor(repository));
    await tester.pumpAndSettle();
    expect(find.text('Không thể tải danh sách phòng.'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Thử lại'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Mobile'), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets('does not overflow with long room content on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = RoomRepository(
      initialRooms: [
        room(
          id: 'room_long',
          name:
              'Phòng học có tên rất dài để kiểm tra hiển thị trên màn hình nhỏ',
          subject: 'Môn học có tên dài cần được rút gọn hợp lý',
          description:
              'Phần mô tả dài dùng để chắc chắn nội dung không làm tràn giao diện '
              'khi ứng dụng chạy trên điện thoại Android có màn hình hẹp.',
          ownerId: 'owner_long',
        ),
      ],
      profiles: const {
        'owner_long': UserProfile(
          uid: 'owner_long',
          displayName: 'Người tạo có tên hiển thị rất dài',
        ),
      },
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(appFor(repository));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Phòng học có tên rất dài'), findsOneWidget);
  });
}
