import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dierb_core/dierb_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NewOrdersScreen extends StatelessWidget {
  const NewOrdersScreen({super.key});

  String get merchantId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    if (merchantId.isEmpty) {
      return const Scaffold(body: Center(child: Text('سجّل الدخول كتاجر أولاً')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('طلبات المتجر', style: TextStyle(fontWeight: FontWeight.w900))),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('orders').where('sellerUID', isEqualTo: merchantId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _StateMessage(icon: Icons.cloud_off_rounded, title: 'تعذر تحميل الطلبات', subtitle: 'راجع الاتصال وحاول مرة أخرى.');
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final ad = a.data()['createdAt'];
              final bd = b.data()['createdAt'];
              final at = ad is Timestamp ? ad.millisecondsSinceEpoch : 0;
              final bt = bd is Timestamp ? bd.millisecondsSinceEpoch : 0;
              return bt.compareTo(at);
            });
          if (docs.isEmpty) {
            return const _StateMessage(
              icon: Icons.receipt_long_outlined,
              title: 'لا توجد طلبات حتى الآن',
              subtitle: 'أول طلب من عميل ديرب سيظهر هنا مباشرة.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _OrderCard(doc: docs[index]),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.doc});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  Future<void> _setStatus(BuildContext context, OrderStatus status) async {
    try {
      await doc.reference.update(<String, dynamic>{
        'status': OrderStatusCodec.toStorage(status),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status.labelAr)));
    } on FirebaseException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تحديث الطلب: ${e.code}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final items = (data['items'] as List?)?.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() ?? const <Map<String, dynamic>>[];
    final status = OrderStatusCodec.fromStorage(data['status']);
    final total = (data['total'] as num?)?.toDouble() ?? 0;
    final customer = data['customerName']?.toString() ?? 'عميل ديرب';
    final phone = data['customerPhone']?.toString() ?? '';
    final address = data['addressText']?.toString() ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text('طلب #${doc.id.substring(0, doc.id.length > 7 ? 7 : doc.id.length)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17))),
            Chip(label: Text(status.labelAr)),
          ]),
          const SizedBox(height: 10),
          Text(customer, style: const TextStyle(fontWeight: FontWeight.w800)),
          if (phone.isNotEmpty) Text(phone),
          if (address.isNotEmpty) Text(address),
          const Divider(height: 24),
          ...items.map((item) {
            final name = item['name']?.toString() ?? 'منتج';
            final qty = (item['quantity'] as num?)?.toInt() ?? 1;
            final price = (item['price'] as num?)?.toDouble() ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [Expanded(child: Text('$name × $qty')), Text('${(price * qty).toStringAsFixed(0)} ج.م')]),
            );
          }),
          const Divider(height: 24),
          Row(children: [
            const Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.w800)),
            const Spacer(),
            Text('${total.toStringAsFixed(0)} ج.م', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 14),
          _actions(context, status),
        ]),
      ),
    );
  }

  Widget _actions(BuildContext context, OrderStatus status) {
    if (status == OrderStatus.waitingMerchantApproval) {
      return Row(children: [
        Expanded(child: OutlinedButton(onPressed: () => _setStatus(context, OrderStatus.rejected), child: const Text('رفض'))),
        const SizedBox(width: 10),
        Expanded(child: FilledButton(onPressed: () => _setStatus(context, OrderStatus.accepted), child: const Text('قبول الطلب'))),
      ]);
    }
    if (status == OrderStatus.accepted) {
      return FilledButton(onPressed: () => _setStatus(context, OrderStatus.preparing), child: const Text('بدء التجهيز'));
    }
    if (status == OrderStatus.preparing) {
      return FilledButton(onPressed: () => _setStatus(context, OrderStatus.readyForPickup), child: const Text('جاهز للاستلام'));
    }
    return const SizedBox.shrink();
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 62, color: const Color(0xFF166534)),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center),
          ]),
        ),
      );
}
