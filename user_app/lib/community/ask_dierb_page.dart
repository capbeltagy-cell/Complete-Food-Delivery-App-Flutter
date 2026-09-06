import 'package:dierb_api_client/dierb_api_client.dart';
import 'package:dierb_core/dierb_core.dart';
import 'package:flutter/material.dart';

import 'community_post_page.dart';

class AskDierbPage extends StatefulWidget {
  const AskDierbPage({super.key});
  @override State<AskDierbPage> createState() => _AskDierbPageState();
}

class _AskDierbPageState extends State<AskDierbPage> {
  final api = DierbApi();
  List<CommunityPost> posts = const [];
  bool loading = true;
  String? error;
  String? cityId;
  CommunityPostType? filter;

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { api.close(); super.dispose(); }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final cities = await api.cities();
      if (cities.isEmpty) throw const DierbApiException(404, 'لا توجد مدينة مفعّلة حاليًا');
      cityId ??= (cities.first as Map)['id'].toString();
      final values = await api.questions(cityId: cityId!);
      final all = values.map((value) { final map = Map<String, dynamic>.from(value as Map); return CommunityPost.fromMap(map['id'].toString(), map); }).toList();
      if (mounted) setState(() { posts = filter == null ? all : all.where((post) => post.type == filter).toList(); loading = false; });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = e is DierbApiException ? e.message : 'تعذر تحميل الأسئلة الآن'; });
    }
  }

  Future<void> _compose() async {
    if (!await api.hasSession) return _loginMessage();
    final created = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => CommunityComposer(api: api, cityId: cityId!));
    if (created == true) await _load();
  }

  void _loginMessage() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سجّل الدخول أولاً علشان تشارك أهل ديرب')));

  @override Widget build(BuildContext context) => SafeArea(child: Scaffold(
    appBar: AppBar(title: const Text('اسأل أهل ديرب', style: TextStyle(fontWeight: FontWeight.w900)), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))]),
    floatingActionButton: FloatingActionButton.extended(onPressed: cityId == null ? null : _compose, icon: const Icon(Icons.add_comment_rounded), label: const Text('اسأل دلوقتي')),
    body: Column(children: [
      SizedBox(height: 54, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), children: [
        _Filter(label: 'الكل', selected: filter == null, tap: () { filter = null; _load(); }),
        ...CommunityPostType.values.map((type) => _Filter(label: postTypeLabel(type), selected: filter == type, tap: () { filter = type; _load(); })),
      ])),
      Expanded(child: loading ? const Center(child: CircularProgressIndicator()) : error != null ? _State(icon: Icons.cloud_off_rounded, text: error!, retry: _load) : posts.isEmpty ? const _State(icon: Icons.forum_outlined, text: 'لسه مفيش أسئلة هنا\nكن أول واحد يسأل أهل ديرب') : RefreshIndicator(onRefresh: _load, child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 100), itemCount: posts.length, separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _PostCard(post: posts[i], onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CommunityPostPage(postId: posts[i].id))).then((_) => _load())),
      ))),
    ]),
  ));
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.onTap}); final CommunityPost post; final VoidCallback onTap;
  @override Widget build(BuildContext context) => Card(clipBehavior: Clip.antiAlias, child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [const CircleAvatar(child: Icon(Icons.person_rounded)), const SizedBox(width: 9), Expanded(child: Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.w800))), if (post.authorType == CommunityAuthorType.merchant) const Chip(label: Text('تاجر')), if (post.authorVerified) const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF166534))]),
    const SizedBox(height: 12), Text(post.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)), if (post.body.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(post.body, maxLines: 3, overflow: TextOverflow.ellipsis)), const SizedBox(height: 13),
    Row(children: [const Icon(Icons.thumb_up_alt_outlined, size: 18), Text(' ${post.helpfulCount} مفيد'), const SizedBox(width: 18), const Icon(Icons.chat_bubble_outline_rounded, size: 18), Text(' ${post.replyCount} رد'), const Spacer(), Text(postTypeLabel(post.type), style: const TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.w700))]),
  ]))));
}

class CommunityComposer extends StatefulWidget {
  const CommunityComposer({super.key, required this.api, required this.cityId}); final DierbApi api; final String cityId;
  @override State<CommunityComposer> createState() => _CommunityComposerState();
}
class _CommunityComposerState extends State<CommunityComposer> {
  final title = TextEditingController(); final body = TextEditingController(); CommunityPostType type = CommunityPostType.question; bool saving = false; String? error;
  Future<void> _save() async {
    if (title.text.trim().length < 3 || body.text.trim().length < 3) { setState(() => error = 'اكتب عنوان وتفاصيل واضحة'); return; }
    setState(() { saving = true; error = null; });
    try { await widget.api.createQuestion({'title': title.text.trim(), 'body': body.text.trim(), 'type': type.name, 'cityId': widget.cityId}); if (mounted) Navigator.pop(context, true); }
    catch (e) { if (mounted) setState(() => error = e is DierbApiException ? e.message : 'تعذر نشر السؤال'); }
    finally { if (mounted) setState(() => saving = false); }
  }
  @override Widget build(BuildContext context) => Padding(padding: EdgeInsets.fromLTRB(18, 16, 18, MediaQuery.viewInsetsOf(context).bottom + 18), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Text('اسأل أهل ديرب', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 14),
    DropdownButtonFormField<CommunityPostType>(initialValue: type, items: CommunityPostType.values.map((v) => DropdownMenuItem(value: v, child: Text(postTypeLabel(v)))).toList(), onChanged: (v) => setState(() => type = v!)),
    const SizedBox(height: 12), TextField(controller: title, decoration: const InputDecoration(labelText: 'عنوان السؤال', border: OutlineInputBorder())), const SizedBox(height: 12), TextField(controller: body, minLines: 4, maxLines: 7, decoration: const InputDecoration(labelText: 'اكتب التفاصيل', border: OutlineInputBorder())),
    if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))), const SizedBox(height: 16), FilledButton.icon(onPressed: saving ? null : _save, icon: saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded), label: const Text('نشر السؤال')),
  ])));
}
class _Filter extends StatelessWidget { const _Filter({required this.label, required this.selected, required this.tap}); final String label; final bool selected; final VoidCallback tap; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsetsDirectional.only(end: 7), child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => tap())); }
class _State extends StatelessWidget { const _State({required this.icon, required this.text, this.retry}); final IconData icon; final String text; final VoidCallback? retry; @override Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 56, color: Colors.grey), const SizedBox(height: 12), Text(text, textAlign: TextAlign.center), if (retry != null) TextButton(onPressed: retry, child: const Text('حاول تاني'))])); }
String postTypeLabel(CommunityPostType type) => const {CommunityPostType.question:'سؤال', CommunityPostType.productRequest:'طلب منتج', CommunityPostType.serviceRequest:'طلب خدمة', CommunityPostType.localInquiry:'استفسار محلي', CommunityPostType.recommendation:'طلب توصية', CommunityPostType.propertyRequest:'طلب عقار', CommunityPostType.jobRequest:'طلب وظيفة'}[type]!;
