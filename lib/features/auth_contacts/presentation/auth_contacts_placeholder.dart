import 'package:flutter/material.dart';

import '../../../core/widgets/feature_placeholder.dart';

class ContactsPlaceholder extends StatelessWidget {
  const ContactsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const FeaturePlaceholder(
    title: 'Danh bạ bạn học',
    owner: 'Thành viên 1 · Auth & Contacts',
    description:
        'Tìm sinh viên, lưu liên hệ và xem danh bạ đã lưu khi mất mạng.',
  );
}

class AccountPlaceholder extends StatelessWidget {
  const AccountPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const FeaturePlaceholder(
    title: 'Tài khoản và hồ sơ',
    owner: 'Thành viên 1 · Auth & Contacts',
    description: 'Đăng ký, đăng nhập, đăng xuất và quản lý hồ sơ sinh viên.',
  );
}
