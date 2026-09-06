import 'dart:async';
import 'package:dierb_api_client/dierb_api_client.dart';
import 'package:flutter/material.dart';

class OrderConversationPage extends StatefulWidget {
  const OrderConversationPage({super.key, required this.orderId, required this.role});
  final String orderId; final String role;
  @override State<OrderConversationPage> createState() => _OrderConversationPageState();
}
class _OrderConversationPageState extends State<OrderConversationPage> {
  final api = DierbApi(); final controller = TextEditingController(); List<dynamic> messages = const []; String userId = ''; bool loading = true; bool sending = false; String? error; Timer? timer;
  @override void initState() { super.initState(); _start(); }
  Future<void> _start() async { try { userId = (await api.profile())['id'].toString(); await _load(); timer = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true)); } catch (e) { if (mounted) setState(() { loading = false; error = e is DierbApiException ? e.message : 'تعذر فتح المحادثة'; }); } }
  Future<void> _load({bool silent = false}) async { try { final value = await api.chatMessages(widget.orderId); if (mounted) setState(() { messages = value; loading = false; error = null; }); } catch (e) { if (mounted && !silent) setState(() { loading = false; error = e is DierbApiException ? e.message : 'تعذر تحميل المحادثة'; }); } }
  Future<void> _send({String? preset, String type = 'text'}) async { final text = (preset ?? controller.text).trim(); if (text.isEmpty || sending) return; setState(() => sending = true); try { await api.sendChatMessage(widget.orderId, text, type: type); controller.clear(); await _load(); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is DierbApiException ? e.message : 'تعذر إرسال الرسالة'))); } finally { if (mounted) setState(() => sending = false); } }
  @override void dispose() { timer?.cancel(); controller.dispose(); api.close(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('محادثة الطلب', style: TextStyle(fontWeight: FontWeight.w900))),
    body: Column(children: [
      Expanded(child: loading ? const Center(child: CircularProgressIndicator()) : error != null ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error!), TextButton(onPressed: _start, child: const Text('حاول تاني'))])) : messages.isEmpty ? const Center(child: Padding(padding: EdgeInsets.all(28), child: Text('ابدأ محادثة بخصوص الطلب. الرسائل ظاهرة فقط لأطراف الطلب.', textAlign: TextAlign.center))) : RefreshIndicator(onRefresh: _load, child: ListView.builder(reverse: true, padding: const EdgeInsets.all(14), itemCount: messages.length, itemBuilder: (_, index) {
        final data = Map<String,dynamic>.from(messages[index] as Map); final mine = data['senderId']?.toString() == userId; final arrived = data['type'] == 'arrived';
        return Align(alignment: mine ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd, child: Container(constraints: const BoxConstraints(maxWidth: 310), margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11), decoration: BoxDecoration(color: arrived ? const Color(0xFFFFE8B5) : mine ? const Color(0xFFDCEFE6) : Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFFDDE5E0))), child: Row(mainAxisSize: MainAxisSize.min, children: [if (arrived) ...[const Icon(Icons.location_on_rounded, size: 19, color: Color(0xFF9A5A00)), const SizedBox(width: 6)], Flexible(child: Text((data['body'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w700)))])));
      }))),
      SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 12), child: Row(children: [Expanded(child: TextField(controller: controller, minLines: 1, maxLines: 4, decoration: const InputDecoration(hintText: 'اكتب رسالة عن الطلب...', prefixIcon: Icon(Icons.chat_bubble_outline_rounded)))), const SizedBox(width: 8), IconButton.filled(onPressed: sending ? null : _send, icon: sending ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded))]))),
    ]),
  );
}
