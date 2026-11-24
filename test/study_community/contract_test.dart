import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:study_chat_app/features/study_community/study_community.dart';

void main() {
  test('RoomRepository implements StudyCommunityContract and watchRooms streams updates', () async {
    final repository = createPreviewRoomRepository();
    addTearDown(repository.dispose);

    final StudyCommunityContract contract = repository;
    final snapshots = <int>[];
    final sub = contract.watchRooms().listen((rooms) {
      snapshots.add(rooms.length);
    });

    await Future<void>.delayed(Duration.zero);
    final created = await contract.createRoomAsync(
      const CreateRoomInput(
        roomName: 'Hệ điều hành',
        subject: 'OS',
        description: 'Ôn thi cuối kỳ',
        ownerId: tv3PreviewUserId,
      ),
    );

    expect(created.roomId, startsWith('room_'));
    expect(await contract.getRoom(created.roomId), isNotNull);
    expect(await contract.getRoom('missing_room'), isNull);
    expect(snapshots, [3, 4]);

    await sub.cancel();
    await contract.createRoomAsync(
      const CreateRoomInput(
        roomName: 'Mạng máy tính',
        subject: 'Network',
        description: '',
        ownerId: tv3PreviewUserId,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(snapshots.length, 2);
  });

  test('study_community.rules.json is valid JSON covering rooms, roomMembers, and roomNotices', () {
    final file = File(
      'lib/features/study_community/integration/study_community.rules.json',
    );
    expect(file.existsSync(), isTrue);

    final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final rules = decoded['rules'] as Map<String, dynamic>;

    expect(rules.containsKey('rooms'), isTrue);
    expect(rules.containsKey('roomMembers'), isTrue);
    expect(rules.containsKey('roomNotices'), isTrue);
    expect(rules.length, 3);
  });
}
