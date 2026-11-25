import 'package:flutter/material.dart';

import '../../../app/contacts.dart' show socialAction;
import '../data/chat_repository.dart';
import 'chat_widgets.dart';

class FollowedQuestionsPage extends StatelessWidget {
  const FollowedQuestionsPage(this.repo, {this.cid, super.key});
  final ChatRepository repo;
  final String? cid;

  static void open(BuildContext context, ChatRepository repo, {String? cid}) =>
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => FollowedQuestionsPage(repo, cid: cid),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Câu mình đang theo dõi')),
    body: StreamBuilder(
      stream: repo.followedQuestions,
      builder: (context, snap) {
        if (snap.hasError) return StatePanel(readableError(snap.error));
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!repo.online) {
          return const StatePanel('Kết nối lại để xem các câu đang theo dõi.');
        }
        final rows = snap.requireData
            .where((r) => cid == null || r.chat.id == cid)
            .toList();
        if (rows.isEmpty) {
          return const StatePanel(
            'Chọn “Mình cũng đang bí” dưới một câu hỏi để theo dõi lời giải.',
          );
        }
        return ListView(
          children: [
            for (final (title, items) in [
              ('Có lời giải mới', rows.where((r) => r.unread)),
              ('Đến ngày ôn', rows.where((r) => !r.unread && r.due)),
              ('Chờ lời giải', rows.where((r) => r.answer == null)),
              (
                'Đã có lời giải',
                rows.where((r) => r.answer != null && !r.unread && !r.due),
              ),
            ])
              if (items.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                for (final item in items)
                  ListTile(
                    leading: Icon(
                      item.answer == null
                          ? Icons.hourglass_empty
                          : Icons.school_outlined,
                    ),
                    title: Text(
                      item.question.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      [
                        item.chat.title,
                        if (item.reviewAt != null)
                          'Ôn ngày ${_day(item.reviewAt!)}',
                      ].join(' · '),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => SolutionPage.open(
                      context,
                      repo,
                      item,
                      practice: item.due && !item.unread,
                    ),
                  ),
              ],
          ],
        );
      },
    ),
  );
}

String _day(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${d.day}/${d.month}/${d.year}';
}

class SolutionPage extends StatefulWidget {
  const SolutionPage(
    this.repo,
    this.cid,
    this.mid, {
    required this.practice,
    super.key,
  });
  final ChatRepository repo;
  final String cid, mid;
  final bool practice;

  static void open(
    BuildContext context,
    ChatRepository repo,
    FollowedQuestion item, {
    bool practice = false,
  }) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => SolutionPage(
        repo,
        item.chat.id,
        item.question.id,
        practice: practice,
      ),
    ),
  );
  @override
  State<SolutionPage> createState() => _SolutionPageState();
}

class _SolutionPageState extends State<SolutionPage> {
  late bool revealed = !widget.practice;
  String? acknowledged;
  Future<void> schedule(FollowedQuestion item) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final next = DateTime(today.year, today.month, today.day + 1);
    final day = await showDatePicker(
      context: context,
      helpText: 'Chọn ngày ôn',
      cancelText: 'Hủy',
      confirmText: 'Lưu lịch ôn',
      firstDate: today,
      initialDate: next,
      lastDate: DateTime(today.year + 3, 12, 31),
    );
    if (day != null && mounted) {
      await socialAction(context, () => widget.repo.scheduleReview(item, day));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.practice ? 'Ôn câu đã theo dõi' : 'Câu hỏi và lời giải',
      ),
    ),
    body: StreamBuilder(
      stream: widget.repo.followedQuestions,
      builder: (context, s) {
        if (s.hasError) return StatePanel(readableError(s.error));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final item = s.requireData
            .where(
              (r) => r.chat.id == widget.cid && r.question.id == widget.mid,
            )
            .firstOrNull;
        if (item == null) {
          return StatePanel(
            widget.repo.online
                ? 'Câu hỏi không còn trong danh sách của bạn.'
                : 'Kết nối lại để xem lời giải.',
          );
        }
        final answer = item.answer;
        if (ModalRoute.isCurrentOf(context) == true &&
            revealed &&
            item.unread &&
            acknowledged != answer!.id) {
          acknowledged = answer.id;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              socialAction(context, () => widget.repo.readSolution(item));
            }
          });
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              item.chat.title,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            SelectableText(
              item.question.content,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 18),
            if (answer == null)
              const Text('Đang chờ người hỏi chốt lời giải.')
            else if (!revealed)
              FilledButton(
                onPressed: () => setState(() => revealed = true),
                child: const Text('Lật xem lời giải'),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lời giải đã chốt',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      SelectableText(answer.content),
                    ],
                  ),
                ),
              ),
            if (answer != null) ...[
              if (revealed)
                TextButton(
                  onPressed: () => setState(() => revealed = false),
                  child: const Text('Tự ôn câu này'),
                ),
              if (item.reviewAt != null)
                Text('Ngày ôn riêng của bạn · ${_day(item.reviewAt!)}'),
              TextButton.icon(
                onPressed: () => schedule(item),
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  item.reviewAt == null ? 'Hẹn ngày ôn' : 'Đổi ngày ôn',
                ),
              ),
              if (item.reviewAt != null && revealed)
                TextButton(
                  onPressed: () => socialAction(
                    context,
                    () => widget.repo.scheduleReview(item, null),
                  ),
                  child: const Text('Đã ôn xong'),
                ),
            ],
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                '/chat',
                arguments: ChatArgs.existing(item.chat),
              ),
              child: const Text('Mở hội thoại'),
            ),
            TextButton(
              onPressed: () => socialAction(context, () async {
                await widget.repo.followQuestion(widget.cid, widget.mid, false);
                if (context.mounted) Navigator.pop(context);
              }),
              child: const Text('Bỏ theo dõi câu hỏi'),
            ),
          ],
        );
      },
    ),
  );
}
