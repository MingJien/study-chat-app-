import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../features/realtime_chat/presentation/chat_widgets.dart';

class SessionForm extends StatefulWidget {
  const SessionForm(this.auth, this.db, {super.key, this.user, this.onProfile});
  final FirebaseAuth auth;
  final FirebaseDatabase db;
  final User? user;
  final VoidCallback? onProfile;
  @override
  State<SessionForm> createState() => _SessionFormState();
}

class _SessionFormState extends State<SessionForm> {
  final email = TextEditingController(),
      password = TextEditingController(),
      name = TextEditingController();
  bool register = false, busy = false;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final user = widget.user;
      if (user != null) {
        final display = name.text.trim();
        if (display.isEmpty || display.length > 50) {
          setState(() => error = 'Nhập tên hiển thị từ 1 đến 50 ký tự.');
          return;
        }
        await widget.db.ref('profiles/${user.uid}').update({
          'uid': user.uid,
          'displayName': display,
          'avatarId': 'avatar_default',
          'email': user.email,
        });
        await user.updateDisplayName(display);
        widget.onProfile?.call();
      } else if (register) {
        await widget.auth.createUserWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text,
        );
      } else {
        await widget.auth.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.user != null;
    final title = profile
        ? 'Tên của bạn'
        : register
        ? 'Tạo tài khoản'
        : 'Đăng nhập';
    final brand = Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xff173f39),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.forum_rounded, color: Color(0xffc9eac8)),
              SizedBox(width: 10),
              Text(
                'Study Chat',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 28),
            child: Text(
              'Phòng thảo luận\nhọc tập',
              style: TextStyle(
                color: Color(0xffe4f2db),
                fontSize: 34,
                height: 1.1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    final form = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        if (profile)
          TextField(
            controller: name,
            maxLength: 50,
            decoration: const InputDecoration(labelText: 'Tên hiển thị'),
            onSubmitted: (_) => submit(),
          )
        else ...[
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email sinh viên'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: password,
            obscureText: true,
            autofillHints: [
              register ? AutofillHints.newPassword : AutofillHints.password,
            ],
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              helperText: register ? 'Ít nhất 6 ký tự' : null,
            ),
            onSubmitted: (_) => submit(),
          ),
        ],
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: busy ? null : submit,
          child: Text(
            busy
                ? 'Đang xử lý…'
                : profile
                ? 'Vào Study Chat'
                : title,
          ),
        ),
        if (!profile)
          TextButton(
            onPressed: busy
                ? null
                : () => setState(() {
                    register = !register;
                    error = null;
                  }),
            child: Text(
              register
                  ? 'Đã có tài khoản? Đăng nhập'
                  : 'Chưa có tài khoản? Đăng ký',
            ),
          ),
      ],
    );
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: LayoutBuilder(
                builder: (_, c) => c.maxWidth >= 640
                    ? IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(child: brand),
                            const SizedBox(width: 36),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                child: form,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [brand, const SizedBox(height: 28), form],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
