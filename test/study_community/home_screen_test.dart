import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_chat_app/features/study_community/study_community.dart';

void main() {
  testWidgets(
    'displays student greeting, joined rooms, featured rooms, and recent conversations',
    (tester) async {
      final repository = createPreviewRoomRepository();
      addTearDown(repository.dispose);

      final openedConversations = <String>[];
      final conversations = [
        RecentConversationSummary(
          conversationId: 'room_preview_mobile',
          title: 'Nhóm Mobile Flutter',
          lastMessage: 'Nhớ nộp bài thực hành thứ Sáu nhé',
          isGroup: true,
          updatedAt: DateTime.utc(2026, 11, 24, 10),
        ),
        RecentConversationSummary(
          conversationId: 'dm_linh_tv3',
          title: 'Nguyễn Khánh Linh',
          lastMessage: 'Chiều nay học nhóm lúc 2h nha',
          isGroup: false,
          updatedAt: DateTime.utc(2026, 11, 24, 9),
          avatarId: 'avatar_linh',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            repository: repository,
            currentUserId: tv3PreviewUserId,
            currentUserProfile: const UserProfile(
              uid: tv3PreviewUserId,
              displayName: 'Bạn (TV3)',
              avatarId: 'avatar_tv3',
            ),
            recentConversations: conversations,
            onOpenConversation: (summary) async {
              openedConversations.add(summary.conversationId);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Xin chào, Bạn (TV3)'), findsOneWidget);
      expect(find.text('Phòng đã tham gia'), findsOneWidget);
      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Ôn tập Cơ sở dữ liệu'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Frontend căn bản'), 200);
      expect(find.text('Phòng mới & nổi bật'), findsOneWidget);
      expect(find.text('Frontend căn bản'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Nguyễn Khánh Linh'), 200);
      expect(find.text('Hội thoại gần đây'), findsOneWidget);
      expect(find.text('Nhóm Mobile Flutter'), findsOneWidget);
      expect(find.text('Nguyễn Khánh Linh'), findsOneWidget);
      expect(find.text('Nhóm'), findsOneWidget);
      expect(find.text('Cá nhân'), findsAtLeastNWidgets(1));

      await tester.tap(find.text('Nguyễn Khánh Linh'));
      await tester.pumpAndSettle();
      expect(openedConversations, ['dm_linh_tv3']);
    },
  );

  testWidgets(
    'shows empty state when no joined rooms and updates live on join/leave',
    (tester) async {
      final repository = RoomRepository(
        profiles: const {
          'owner_uid': UserProfile(uid: 'owner_uid', displayName: 'Chủ phòng'),
          'student_uid': UserProfile(
            uid: 'student_uid',
            displayName: 'Sinh viên A',
          ),
        },
        initialRooms: [
          StudyRoom(
            roomId: 'room_1',
            roomName: 'Cấu trúc dữ liệu',
            subject: 'DSA',
            description: 'Ôn thuật toán',
            ownerId: 'owner_uid',
            createdAt: DateTime.utc(2026, 11, 20),
          ),
        ],
        initialMembers: const {
          'room_1': [RoomMember(uid: 'owner_uid', role: RoomRole.owner)],
        },
      );
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            repository: repository,
            currentUserId: 'student_uid',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bạn chưa tham gia phòng học nào'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Khám phá phòng'),
        findsOneWidget,
      );
      expect(find.text('Chưa có hội thoại gần đây.'), findsOneWidget);

      await repository.joinRoom('room_1', currentUserId: 'student_uid');
      await tester.pumpAndSettle();

      expect(find.text('Bạn chưa tham gia phòng học nào'), findsNothing);
      expect(
        find.text('Bạn đã tham gia tất cả phòng hiện có.'),
        findsOneWidget,
      );
      expect(find.text('Đã tham gia'), findsOneWidget);

      await repository.leaveRoom('room_1', currentUserId: 'student_uid');
      await tester.pumpAndSettle();

      expect(find.text('Bạn chưa tham gia phòng học nào'), findsOneWidget);
    },
  );

  testWidgets('handles loading, error, and retry states', (tester) async {
    var attempts = 0;
    final completer = Completer<void>();
    final repository = RoomRepository(
      initialRooms: [
        StudyRoom(
          roomId: 'room_1',
          roomName: 'Mobile',
          subject: 'Flutter',
          description: 'Mô tả',
          ownerId: 'owner_uid',
          createdAt: DateTime.utc(2026, 11, 20),
        ),
      ],
      onLoad: () async {
        attempts++;
        if (attempts == 1) {
          await completer.future;
          throw Exception('network error');
        }
      },
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(repository: repository, currentUserId: 'owner_uid'),
      ),
    );
    expect(find.text('Đang tải trang chủ...'), findsOneWidget);

    completer.complete();
    await tester.pumpAndSettle();
    expect(find.text('Không thể tải dữ liệu trang chủ.'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Mobile'), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets(
    'quick navigation callbacks work and opening a room navigates to RoomDetailScreen',
    (tester) async {
      final repository = createPreviewRoomRepository();
      addTearDown(repository.dispose);
      final tapped = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            repository: repository,
            currentUserId: tv3PreviewUserId,
            onNavigateToRooms: () => tapped.add('rooms'),
            onNavigateToChats: () => tapped.add('chats'),
            onNavigateToContacts: () => tapped.add('contacts'),
            onNavigateToProfile: () => tapped.add('profile'),
            onNavigateToSettings: () => tapped.add('settings'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Phòng học'));
      await tester.tap(find.widgetWithText(OutlinedButton, 'Tin nhắn'));
      await tester.tap(find.widgetWithText(OutlinedButton, 'Bạn học'));
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cá nhân'));
      await tester.tap(find.byTooltip('Cài đặt'));
      await tester.pumpAndSettle();

      expect(tapped, ['rooms', 'chats', 'contacts', 'profile', 'settings']);

      await tester.tap(find.text('Frontend căn bản'));
      await tester.pumpAndSettle();
      expect(find.byType(RoomDetailScreen), findsOneWidget);
    },
  );

  testWidgets(
    'fits narrow Android viewport with scaled text and long content',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = RoomRepository(
        profiles: const {
          'long_uid': UserProfile(
            uid: 'long_uid',
            displayName: 'Nguyễn Minh Hiếu Sinh Viên Tên Rất Dài',
            avatarId: 'avatar_tv3',
          ),
        },
        initialRooms: [
          StudyRoom(
            roomId: 'room_long',
            roomName: 'Phòng học có tên rất dài để kiểm tra tràn màn hình ' * 2,
            subject: 'Lập trình di động nâng cao với Flutter',
            description: 'Mô tả dài',
            ownerId: 'long_uid',
            createdAt: DateTime.utc(2026, 11, 20),
          ),
        ],
        initialMembers: const {
          'room_long': [RoomMember(uid: 'long_uid', role: RoomRole.owner)],
        },
      );
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: HomeScreen(
              repository: repository,
              currentUserId: 'long_uid',
              recentConversations: [
                RecentConversationSummary(
                  conversationId: 'c1',
                  title: 'Hội thoại có tiêu đề rất dài cho màn hình hẹp',
                  lastMessage:
                      'Tin nhắn gần nhất cũng dài không kém để thử tràn',
                  isGroup: true,
                  updatedAt: DateTime.utc(2026, 11, 24),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );
}
