import 'package:dierb_api_client/dierb_api_client.dart';
import 'package:dierb_core/dierb_core.dart';
import 'package:flutter/material.dart';

class CommunityPostPage extends StatefulWidget {
  const CommunityPostPage({super.key, required this.postId}); final String postId;
  @override State<CommunityPostPage> createState() => _CommunityPostPageState();
}
class _CommunityPostPageState extends State<CommunityPostPage> {
  final api = DierbApi(); final reply = TextEditingController(); Map<String, dynamic>? data; bool loading = true; bool sending = false; String? error;
  @override void initState() { super.initState(); _load(); }
  @override void dispose() { api.close(); reply.dispose(); super.dispose(); }
  Future<void> _load() async { try { final value = await api.question(widget.postId); if (mounted) setState(() { data = value; loading = false; error = null; }); } catch (e) { if (mounted) setState(() { loading = false; error = e is DierbApiException ? e.message : 'تعذر تحميل السؤال'; }); } }
  Future<bool> _authorized() async { if (await api.hasSession) return true; if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سجّل الدخول أولاً'))); return false; }
  Future<void> _helpful() async { if (!await _authorized()) return; try { await api.markHelpful(widget.postId); await _load(); } catch (e) { _show(e); } }
  Future<void> _report() async { if (!await _authorized()) return; try { await api.report(targetType: 'question', targetId: widget.postId, reason: 'بلاغ مستخدم عن محتوى غير مناسب'); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال البلاغ للمراجعة'))); } catch (e) { _show(e); } }
  Future<void> _send() async { if (reply.text.trim().isEmpty || !await _authorized()) return; setState(() => sending = true); try { await api.answerQuestion(widget.postId, reply.text.trim()); reply.clear(); await _load(); } catch (e) { _show(e); } finally { if (mounted) setState(() => sending = false); } }
  void _show(Object e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is DierbApiException ? e.message : 'تعذر تنفيذ الطلب'))); }
  @override Widget build(BuildContext context) {
    final post = data == null ? null : CommunityPost.fromMap(widget.postId, data!); final answers = data?['answers'] as List? ?? const [];
    return Scaffold(appBar: AppBar(title: const Text('تفاصيل السؤال'), actions: [PopupMenuButton<String>(onSelected: (_) => _report(), itemBuilder: (_) => const [PopupMenuItem(value: 'report', child: Text('إبلاغ عن المحتوى'))])]), body: loading ? const Center(child: CircularProgressIndicator()) : error != null ? Center(child: Text(error!)) : Column(children: [
      Expanded(child: RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
        Text(post!.title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)), const SizedBox(height: 9), Text(post.body, style: const TextStyle(fontSize: 16, height: 1.6)), const SizedBox(height: 12), Align(alignment: AlignmentDirectional.centerStart, child: OutlinedButton.icon(onPressed: _helpful, icon: const Icon(Icons.thumb_up_alt_outlined), label: Text('${post.helpfulCount} مفيد'))),
        const Divider(height: 32), const Text('الردود', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 10),
        if (answers.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('لسه مفيش ردود'))) else ...answers.map((raw) { final map = Map<String,dynamic>.from(raw as Map); final item = CommunityReply.fromMap(map['id'].toString(), widget.postId, map); return ListTile(contentPadding: EdgeInsets.zero, leading: const CircleAvatar(child: Icon(Icons.person_rounded)), title: Row(children: [Text(item.authorName), if (item.authorType == CommunityAuthorType.merchant) const Padding(padding: EdgeInsetsDirectional.only(start: 6), child: Icon(Icons.store_rounded, size: 16))]), subtitle: Padding(padding: const EdgeInsets.only(top: 5), child: Text(item.body))); }),
      ]))),
      SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 10), child: Row(children: [Expanded(child: TextField(controller: reply, decoration: const InputDecoration(hintText: 'اكتب ردك...', filled: true, border: OutlineInputBorder(borderSide: BorderSide.none)))), const SizedBox(width: 8), IconButton.filled(onPressed: sending ? null : _send, icon: sending ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded))]))),
    ]));
  }
}
