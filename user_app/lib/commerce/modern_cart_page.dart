import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dierb_core/dierb_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_controller.dart';

class ModernCartPage extends StatelessWidget {
  const ModernCartPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('السلة', style: TextStyle(fontWeight: FontWeight.w900))),
    body: Consumer<CartController>(builder: (_, cart, __) {
      if (cart.isEmpty) return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.shopping_cart_outlined, size: 56, color: Colors.grey), SizedBox(height: 10), Text('السلة فاضية')]));
      return Column(children: [
        Expanded(child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: cart.items.length, itemBuilder: (_, index) {
          final item = cart.items[index];
          return Card(child: ListTile(title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${item.price.toStringAsFixed(2)} ج.م'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(onPressed: () => cart.changeQuantity(item.productId, item.quantity - 1), icon: const Icon(Icons.remove_circle_outline)),
            Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w900)),
            IconButton(onPressed: () => cart.changeQuantity(item.productId, item.quantity + 1), icon: const Icon(Icons.add_circle_outline)),
          ])));
        })),
        SafeArea(top: false, child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          Expanded(child: Text('الإجمالي: ${cart.subtotal.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
          FilledButton(onPressed: () => _checkout(context, cart), child: const Text('إتمام الطلب')),
        ]))),
      ]);
    }),
  );
}

Future<void> _checkout(BuildContext context, CartController cart) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سجّل الدخول من حسابي قبل إتمام الطلب'))); return; }
  final profile = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  final data = profile.data() ?? <String, dynamic>{};
  final name = TextEditingController(text: data['name']?.toString() ?? user.displayName ?? '');
  final phone = TextEditingController(text: data['phone']?.toString() ?? '');
  final address = TextEditingController(text: data['address']?.toString() ?? '');
  final notes = TextEditingController();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, builder: (sheetContext) => Padding(
    padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.viewInsetsOf(sheetContext).bottom + 18),
    child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('بيانات التوصيل', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم')),
      TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'الهاتف')),
      TextField(controller: address, decoration: const InputDecoration(labelText: 'العنوان بالتفصيل')),
      TextField(controller: notes, maxLines: 2, decoration: const InputDecoration(labelText: 'ملاحظات للمتجر (اختياري)')),
      const SizedBox(height: 10), const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.payments_outlined), title: Text('الدفع عند الاستلام')),
      FilledButton(onPressed: () async {
        if (name.text.trim().isEmpty || phone.text.trim().isEmpty || address.text.trim().isEmpty) { ScaffoldMessenger.of(sheetContext).showSnackBar(const SnackBar(content: Text('أكمل بيانات التوصيل'))); return; }
        final ref = FirebaseFirestore.instance.collection('orders').doc();
        await ref.set({
          'orderId': ref.id, 'orderedBy': user.uid, 'customerName': name.text.trim(), 'customerPhone': phone.text.trim(),
          'addressText': address.text.trim(), 'notes': notes.text.trim(), 'paymentMethod': 'cashOnDelivery',
          'storeId': cart.storeId, 'storeName': cart.storeName, 'sellerUID': cart.merchantId, 'riderUID': '',
          'items': cart.items.map((item) => item.toOrderMap()).toList(), 'subtotal': cart.subtotal,
          'deliveryFee': 0, 'total': cart.subtotal, 'status': OrderStatus.waitingMerchantApproval.name,
          'cityId': 'dierb-nigm', 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(),
        });
        cart.clear();
        if (sheetContext.mounted) Navigator.pop(sheetContext);
        if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل طلبك بنجاح'))); }
      }, child: Text('تأكيد الطلب • ${cart.subtotal.toStringAsFixed(2)} ج.م')),
    ])),
  ));
}
