import 'package:flutter/material.dart';

import '../../../core/widgets/feature_placeholder.dart';

class HomePlaceholder extends StatelessWidget {
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const FeaturePlaceholder(
    title: 'Không gian học tập',
    owner: 'Thành viên 3 · Study Community & App UI',
    description: 'Trang chủ tổng hợp phòng học và các cuộc trò chuyện gần đây.',
  );
}

class RoomsPlaceholder extends StatelessWidget {
  const RoomsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const FeaturePlaceholder(
    title: 'Phòng thảo luận',
    owner: 'Thành viên 3 · Study Community & App UI',
    description: 'Tạo, tìm kiếm, tham gia phòng và quản lý thông báo ghim.',
  );
}
