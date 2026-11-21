import 'package:flutter/material.dart';

import '../../../core/widgets/feature_placeholder.dart';

class ConversationsPlaceholder extends StatelessWidget {
  const ConversationsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const FeaturePlaceholder(
    title: 'Hội thoại',
    owner: 'Thành viên 2 · Realtime Chat & Presence',
    description:
        'Chat cá nhân, chat nhóm, trạng thái online và lịch sử đã lưu.',
  );
}
