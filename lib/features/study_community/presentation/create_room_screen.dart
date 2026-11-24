import 'package:flutter/material.dart';

import '../data/room_repository.dart';
import '../domain/study_room_models.dart';
import 'room_detail_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({
    super.key,
    required this.repository,
    required this.currentUserId,
    this.onOpenDiscussion,
  });

  final RoomRepository repository;
  final String currentUserId;
  final OpenRoomDiscussion? onOpenDiscussion;

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomName = TextEditingController();
  final _subject = TextEditingController();
  final _description = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _roomName.dispose();
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  String? _validateRoomName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return 'Nhập tên phòng.';
    if (name.characters.length > 60) return 'Tên phòng tối đa 60 ký tự.';
    return null;
  }

  void _createRoom() {
    if (_submitted || !_formKey.currentState!.validate()) return;
    setState(() => _submitted = true);

    final repository = widget.repository;
    final room = repository.createRoom(
      roomName: _roomName.text,
      subject: _subject.text,
      description: _description.text,
      ownerId: widget.currentUserId,
    );

    FocusScope.of(context).unfocus();
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute(
        builder: (context) => RoomDetailScreen(
          room: room,
          repository: repository,
          currentUserId: widget.currentUserId,
          onOpenDiscussion: widget.onOpenDiscussion,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo phòng học')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _roomName,
                decoration: const InputDecoration(labelText: 'Tên phòng'),
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                validator: _validateRoomName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subject,
                decoration: const InputDecoration(labelText: 'Môn học'),
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                validator: (value) => (value ?? '').characters.length > 60
                    ? 'Môn học tối đa 60 ký tự.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  hintText: 'Không bắt buộc',
                  alignLabelWithHint: true,
                ),
                textCapitalization: TextCapitalization.sentences,
                minLines: 3,
                maxLines: 5,
                validator: (value) => (value ?? '').characters.length > 200
                    ? 'Mô tả tối đa 200 ký tự.'
                    : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitted ? null : _createRoom,
                child: const Text('Tạo phòng'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
