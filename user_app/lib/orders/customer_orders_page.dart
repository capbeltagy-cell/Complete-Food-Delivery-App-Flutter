import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dierb_core/dierb_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum _OrderFilter { active, completed, cancelled }

class CustomerOrdersPage extends StatefulWidget {
  const CustomerOrdersPage({super.key});
  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage> {
  _OrderFilter filter = _OrderFilter.active;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Scaffold(
          appBar: AppBar(title: const Text('طلباتي', style: TextStyle(fontWeight: FontWeight.w900))),
          body: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, auth) {
              final user = auth.data;
              if (user == null) return const _OrdersMessage(icon: Icons.lock_outline_rounded, title: 'سجّل الدخول علشان تتابع طلباتك');
              return Column(children: [
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: SegmentedButton<_OrderFilter>(
                  segments: const [
                    ButtonSegment(value: _OrderFilter.active, label: Text('الحالية')),
                    ButtonSegment(value: _OrderFilter.completed, label: Text('المكتملة')),
                    ButtonSegment(value: _OrderFilter.cancelled, label: Text('الملغية/المرفوضة')),
                  ],
                  selected: {filter}, onSelectionChanged: (value) => setState(() => filter = value.first),
                )),
                const SizedBox(height: 8),
                Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('orders').where('orderedBy', isEqualTo: user.uid).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return _OrdersMessage(icon: Icons.error_outline, title: 'تعذر تحميل الطلبات', detail: snapshot.error.toString());
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final docs = snapshot.data!.docs.where((doc) => _matches(doc.data())).toList()
                      ..sort((a, b) => _orderMillis(b.data()).compareTo(_orderMillis(a.data())));
                    if (docs.isEmpty) return const _OrdersMessage(icon: Icons.receipt_long_outlined, title: 'مفيش طلبات في القسم ده');
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 90), itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) => _OrderCard(id: docs[index].id, data: docs[index].data()),
                    );
                  },
                )),
              ]);
            },
          ),
        ),
      );

  bool _matches(Map<String, dynamic> data) {
    final status = OrderStatusCodec.fromStorage(data['status']?.toString());
    if (filter == _OrderFilter.completed) return status == OrderStatus.delivered;
    if (filter == _OrderFilter.cancelled) return status == OrderStatus.cancelled || status == OrderStatus.rejected;
    return status != OrderStatus.delivered && status != OrderStatus.cancelled && status != OrderStatus.rejected;
  }
}

int _orderMillis(Map<String, dynamic> data) {
  final value = data['createdAt'] ?? data['orderTime'];
  if (value is Timestamp) return value.millisecondsSinceEpoch;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.id, required this.data});
  final String id;
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    final status = OrderStatusCodec.fromStorage(data['status']?.toString());
    final total = (data['total'] ?? data['totolAmmount'] ?? 0) as num;
    return Card(child: InkWell(
      borderRadius: BorderRadius.circular(16), onTap: () => _showDetails(context),
      child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text('طلب #${id.length > 8 ? id.substring(id.length - 8) : id}', style: const TextStyle(fontWeight: FontWeight.w900))), Text('${total.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.w900))]),
        const SizedBox(height: 9),
        Row(children: [Icon(_statusIcon(status), color: const Color(0xFF166534), size: 20), const SizedBox(width: 7), Text(status.labelAr, style: const TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.w800))]),
        if ((data['storeName'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 7), child: Text(data['storeName'].toString())),
      ])),
    ));
  }

  void _showDetails(BuildContext context) {
    final status = OrderStatusCodec.fromStorage(data['status']?.toString());
    final items = (data['items'] as List?)?.whereType<Map>().toList() ?? const [];
    showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => DraggableScrollableSheet(expand: false, initialChildSize: .72, builder: (_, controller) => ListView(controller: controller, padding: const EdgeInsets.all(20), children: [
      Text('تفاصيل الطلب #${id.length > 8 ? id.substring(id.length - 8) : id}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      const SizedBox(height: 16),
      _Timeline(current: status),
      const Divider(height: 30),
      if ((data['storeName'] ?? '').toString().isNotEmpty) ListTile(leading: const Icon(Icons.storefront_outlined), title: Text(data['storeName'].toString())),
      ListTile(leading: const Icon(Icons.location_on_outlined), title: const Text('عنوان التوصيل'), subtitle: Text((data['addressText'] ?? data['address'] ?? data['addressId'] ?? 'غير محدد').toString())),
      if ((data['notes'] ?? '').toString().isNotEmpty) ListTile(leading: const Icon(Icons.notes_rounded), title: const Text('ملاحظات'), subtitle: Text(data['notes'].toString())),
      const Text('المنتجات', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
      if (items.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('تفاصيل المنتجات غير متاحة لهذا الطلب.')),
      ...items.map((item) => ListTile(title: Text((item['name'] ?? 'منتج').toString()), subtitle: Text('الكمية: ${item['quantity'] ?? 1}'), trailing: Text('${item['price'] ?? 0} ج.م'))),
      const Divider(),
      ListTile(title: const Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.w900)), trailing: Text('${data['total'] ?? data['totolAmmount'] ?? 0} ج.م', style: const TextStyle(fontWeight: FontWeight.w900))),
    ])));
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.current});
  final OrderStatus current;
  @override Widget build(BuildContext context) {
    const flow = [OrderStatus.received, OrderStatus.waitingMerchantApproval, OrderStatus.accepted, OrderStatus.preparing, OrderStatus.readyForPickup, OrderStatus.pickedUpByRider, OrderStatus.onTheWay, OrderStatus.delivered];
    if (current == OrderStatus.cancelled) return const ListTile(leading: Icon(Icons.cancel_rounded, color: Colors.red), title: Text('ملغي', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900)));
    if (current == OrderStatus.rejected) return const ListTile(leading: Icon(Icons.block_rounded, color: Colors.red), title: Text('رفض المتجر الطلب', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900)));
    final currentIndex = flow.indexOf(current);
    return Column(children: List.generate(flow.length, (index) => Row(children: [
      Icon(index <= currentIndex ? Icons.check_circle_rounded : Icons.radio_button_unchecked, color: index <= currentIndex ? const Color(0xFF166534) : Colors.grey),
      const SizedBox(width: 10), Expanded(child: Text(flow[index].labelAr, style: TextStyle(fontWeight: index == currentIndex ? FontWeight.w900 : FontWeight.normal))),
    ])));
  }
}

IconData _statusIcon(OrderStatus status) {
  if (status == OrderStatus.delivered) return Icons.check_circle_outline;
  if (status == OrderStatus.cancelled || status == OrderStatus.rejected) return Icons.cancel_outlined;
  if (status == OrderStatus.onTheWay || status == OrderStatus.pickedUpByRider) return Icons.delivery_dining;
  return Icons.schedule_rounded;
}

class _OrdersMessage extends StatelessWidget {
  const _OrdersMessage({required this.icon, required this.title, this.detail});
  final IconData icon; final String title; final String? detail;
  @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 54, color: Colors.grey), const SizedBox(height: 12), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)), if (detail != null) Padding(padding: const EdgeInsets.only(top: 7), child: Text(detail!, maxLines: 2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey))) ])));
}
