import 'package:flutter_test/flutter_test.dart';
import 'package:study_chat_app/features/study_community/study_community.dart';

void main() {
  late RoomRepository repository;
  late StudyRoom room;
  setUp(() {
    repository = RoomRepository();
    room = repository.createRoom(
      roomName: 'Mobile',
      subject: '',
      description: '',
      ownerId: 'owner',
    );
  });
  tearDown(() => repository.dispose());

  test(
    'owner join preserves role and discussion requires current membership',
    () async {
      await repository.joinRoom(room.roomId, currentUserId: 'owner');
      expect(repository.memberOf(room.roomId, 'owner')?.role, RoomRole.owner);
      expect(repository.memberCountOf(room.roomId), 1);
      expect(
        () =>
            repository.requireMembership(room.roomId, currentUserId: 'member'),
        throwsA(isA<RoomMembershipException>()),
      );
      await repository.joinRoom(room.roomId, currentUserId: 'member');
      repository.requireMembership(room.roomId, currentUserId: 'member');
      await repository.leaveRoom(room.roomId, currentUserId: 'member');
      expect(
        () =>
            repository.requireMembership(room.roomId, currentUserId: 'member'),
        throwsA(isA<RoomMembershipException>()),
      );
    },
  );

  test(
    'join and leave are idempotent, preserve other UIDs and notify',
    () async {
      var changes = 0;
      repository.addListener(() => changes++);
      await Future.wait(
        List.generate(
          4,
          (_) => repository.joinRoom(room.roomId, currentUserId: 'member'),
        ),
      );
      expect(repository.memberCountOf(room.roomId), 2);
      expect(repository.memberOf(room.roomId, 'member')?.role, RoomRole.member);
      expect(changes, 1);
      await Future.wait(
        List.generate(
          4,
          (_) => repository.leaveRoom(room.roomId, currentUserId: 'member'),
        ),
      );
      expect(repository.memberCountOf(room.roomId), 1);
      expect(repository.memberOf(room.roomId, 'member'), isNull);
      expect(repository.memberOf(room.roomId, 'owner')?.role, RoomRole.owner);
      expect(changes, 2);
    },
  );

  test('owner cannot leave, even with a missing membership record', () async {
    await expectLater(
      repository.leaveRoom(room.roomId, currentUserId: 'owner'),
      throwsA(isA<RoomMembershipException>()),
    );
    final incomplete = RoomRepository(initialRooms: [room]);
    addTearDown(incomplete.dispose);
    await expectLater(
      incomplete.leaveRoom(room.roomId, currentUserId: 'owner'),
      throwsA(isA<RoomMembershipException>()),
    );
    expect(repository.memberCountOf(room.roomId), 1);
  });

  test('missing rooms and blank UIDs fail without mutation', () async {
    await expectLater(
      repository.joinRoom('missing', currentUserId: 'member'),
      throwsA(isA<RoomMembershipException>()),
    );
    await expectLater(
      repository.leaveRoom('missing', currentUserId: 'member'),
      throwsA(isA<RoomMembershipException>()),
    );
    await expectLater(
      repository.joinRoom(room.roomId, currentUserId: ' '),
      throwsA(isA<RoomMembershipException>()),
    );
    expect(repository.memberCountOf(room.roomId), 1);
  });
}
