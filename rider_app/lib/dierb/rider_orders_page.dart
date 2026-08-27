import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dierb_core/dierb_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RiderOrdersPage extends StatelessWidget {
  const RiderOrdersPage({super.key, required this.mode});

  final RiderOrdersMode mode;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      return const Scaffold(body: Center(child: Text('سجّل الدخول أولاً')));
    }

    final Query<Map<String, dynamic>> query = mode == RiderOrdersMode.available
        ? FirebaseFirestore.instance
            .collection('orders')
            .where('status', isEqualTo: OrderStatus.readyForPickup.name)
            .where('riderUID', isEqualTo: '')
        : FirebaseFirestore.instance.collection('orders').where('riderUID', isEqualTo: uid);

    return Scaffold(
      appBar: AppBar(title: Text(mode.title, style: const TextStyle(fontWeight: FontWeight.w900))),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _MessageState(
              icon: Icons.cloud_off_rounded,
              title: 'تعذر تحميل الطلبات',
              subtitle: snapshot.error.toString(),
            );
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs.where((doc) {
            final status = OrderStatusCodec.fromStorage(doc.data()['status']);
            switch (mode) {
              case RiderOrdersMode.available:
                return status == OrderStatus.readyForPickup && (doc.data()['riderUID']?.toString() ?? '').isEmpty;
              case RiderOrdersMode.pickup:
                return status == OrderStatus.pickedUpByRider;
              case RiderOrdersMode.delivering:
                return status == OrderStatus.onTheWay;
              case RiderOrdersMode.history:
                return status == OrderStatus.delivered;
            }
          }).toList()
            ..sort((a, b) => _dateOf(b.data()).compareTo(_dateOf(a.data())));

          if (docs.isEmpty) {
            return _MessageState(
              icon: mode == RiderOrdersMode.history ? Icons.history_rounded : Icons.delivery_dining_rounded,
              title: mode.emptyTitle,
              subtitle: mode.emptySubtitle,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _RiderOrderCard(order: docs[index], mode: mode),
          );
        },
      ),
    );
  }
}

enum RiderOrdersMode { available, pickup, delivering, history }

extension RiderOrdersModeText on RiderOrdersMode {
  String get title {
    switch (this) {
      case RiderOrdersMode.available:
        return 'طلبات توصيل متاحة';
      case RiderOrdersMode.pickup:
        return 'طلبات استلمتها';
      case RiderOrdersMode.delivering:
        return 'في الطريق للعميل';
      case RiderOrdersMode.history:
        return 'سجل التوصيل';
    }
  }

  String get emptyTitle {
    switch (this) {
      case RiderOrdersMode.available:
        return 'مفيش طلبات جاهزة دلوقتي';
      case RiderOrdersMode.pickup:
        return 'مفيش طلبات مستلمة';
      case RiderOrdersMode.delivering:
        return 'مفيش توصيلات في الطريق';
      case RiderOrdersMode.history:
        return 'لسه مفيش توصيلات مكتملة';
    }
  }

  String get emptySubtitle {
    switch (this) {
      case RiderOrdersMode.available:
        return 'أول ما متجر يجهز طلب هتلاقيه هنا.';
      case RiderOrdersMode.pickup:
        return 'استلم طلب من قائمة الطلبات المتاحة.';
      case RiderOrdersMode.delivering:
        return 'بعد استلام الطلب من المتجر ابدأ التوصيل.';
      case RiderOrdersMode.history:
        return 'الطلبات المسلّمة هتظهر هنا.';
    }
  }
}

class _RiderOrderCard extends StatefulWidget {
  const _RiderOrderCard({required this.order, required this.mode});

  final QueryDocumentSnapshot<Map<String, dynamic>> order;
  final RiderOrdersMode mode;

  @override
  State<_RiderOrderCard> createState() => _RiderOrderCardState();
}

class _RiderOrderCardState extends State<_RiderOrderCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.order.data();
    final status = OrderStatusCodec.fromStorage(data['status']);
    final items = (data['items'] as List?)?.whereType<Map>().toList() ?? const <Map>[];
    final total = (data['total'] as num?)?.toDouble() ?? 0;
    final store = data['storeName']?.toString() ?? 'متجر ديرب';
    final customer = data['customerName']?.toString() ?? 'العميل';
    final phone = data['customerPhone']?.toString() ?? '';
    final address = data['addressText']?.toString() ?? data['address']?.toString() ?? '';

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5EC),
                  child: Icon(Icons.storefront_rounded, color: Color(0xFF166534)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(store, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      Text(status.labelAr, style: const TextStyle(color: Color(0xFF166534), fontSize: 12)),
                    ],
                  ),
                ),
                Text('${total.toStringAsFixed(0)} ج.م', style: const TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
            const Divider(height: 24),
            Text('العميل: $customer', style: const TextStyle(fontWeight: FontWeight.w700)),
            if (phone.isNotEmpty) Text('الهاتف: $phone'),
            if (address.isNotEmpty) ...[
              const SizedBox(height: 5),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 5),
                Expanded(child: Text(address)),
              ]),
            ],
            if (items.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                items.map((item) {
                  final name = item['name']?.toString() ?? 'منتج';
                  final qty = item['quantity'] ?? 1;
                  return '$qty × $name';
                }).join(' • '),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
            const SizedBox(height: 14),
            if (widget.mode == RiderOrdersMode.available)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _claim,
                  icon: const Icon(Icons.delivery_dining_rounded),
                  label: Text(_busy ? 'جاري الاستلام...' : 'استلام الطلب'),
                ),
              ),
            if (widget.mode == RiderOrdersMode.pickup)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : () => _changeStatus(OrderStatus.onTheWay),
                  icon: const Icon(Icons.route_rounded),
                  label: Text(_busy ? 'جاري التحديث...' : 'خرجت للتوصيل'),
                ),
              ),
            if (widget.mode == RiderOrdersMode.delivering)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : () => _changeStatus(OrderStatus.delivered),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: Text(_busy ? 'جاري التحديث...' : 'تم التسليم للعميل'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _claim() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      final riderSnap = await FirebaseFirestore.instance.collection('riders').doc(user.uid).get();
      final rider = riderSnap.data() ?? <String, dynamic>{};
      final status = rider['status']?.toString() ?? '';
      if (status != 'approved' && status != 'Approved') {
        throw StateError('حساب المندوب غير معتمد بعد');
      }
      final riderName = rider['riderName']?.toString() ?? user.displayName ?? 'مندوب ديرب';
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final fresh = await tx.get(widget.order.reference);
        final data = fresh.data() ?? <String, dynamic>{};
        final currentStatus = OrderStatusCodec.fromStorage(data['status']);
        final currentRider = data['riderUID']?.toString() ?? '';
        if (currentStatus != OrderStatus.readyForPickup || currentRider.isNotEmpty) {
          throw StateError('الطلب استلمه مندوب آخر');
        }
        tx.update(widget.order.reference, <String, dynamic>{
          'riderUID': user.uid,
          'riderName': riderName,
          'status': OrderStatus.pickedUpByRider.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم استلام الطلب')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeStatus(OrderStatus next) async {
    setState(() => _busy = true);
    try {
      await widget.order.reference.update(<String, dynamic>{
        'status': next.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.labelAr)));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 58, color: Colors.grey),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

DateTime _dateOf(Map<String, dynamic> data) {
  final updated = data['updatedAt'];
  if (updated is Timestamp) return updated.toDate();
  final created = data['createdAt'];
  if (created is Timestamp) return created.toDate();
  return DateTime.fromMillisecondsSinceEpoch(0);
}
