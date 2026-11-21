import 'package:flutter/material.dart';

import '../features/auth_contacts/auth_contacts.dart';
import '../features/realtime_chat/realtime_chat.dart';
import '../features/study_community/study_community.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _pages = <Widget>[
    HomePlaceholder(),
    RoomsPlaceholder(),
    ConversationsPlaceholder(),
    ContactsPlaceholder(),
    AccountPlaceholder(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study Chat · Khung dự án nhóm')),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            label: 'Phòng học',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            label: 'Tin nhắn',
          ),
          NavigationDestination(
            icon: Icon(Icons.contacts_outlined),
            label: 'Bạn học',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}
