import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dierb_core/dierb_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EarningScreen extends StatelessWidget {
  const EarningScreen({super.key});

  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الأرباح', style: TextStyle(fontWeight: FontWeight.w900))),
      body: uid.isEmpty
          ? const Center(child: Text('سجّل الدخول أولاً'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('orders').where('sellerUID', isEqualTo: uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('تعذر تحميل الأرباح'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final delivered = snapshot.data!.docs.where((doc) => OrderStatusCodec.fromStorage(doc.data()['status']) == OrderStatus.delivered).toList();
                final total = delivered.fold<double>(0, (sum, doc) => sum + ((doc.data()['total'] as num?)?.toDouble() ?? 0));
                return ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: const Color(0xFFE0F2E9), borderRadius: BorderRadius.circular(24)),
                      child: Column(children: [
                        const Icon(Icons.account_balance_wallet_rounded, size: 46, color: Color(0xFF166534)),
                        const SizedBox(height: 12),
                        Text('${total.toStringAsFixed(0)} ج.م', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
                        const Text('إجمالي مبيعات الطلبات المسلّمة'),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    Card(child: ListTile(leading: const Icon(Icons.receipt_long_rounded), title: const Text('طلبات تم تسليمها'), trailing: Text('${delivered.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)))),
                    const SizedBox(height: 10),
                    const Text('القيمة المعروضة هي إجمالي مبيعات المتجر من الطلبات التي وصلت لحالة تم التسليم، وليست رصيد تحويل بنكي.', style: TextStyle(color: Colors.black54)),
                  ],
                );
              },
            ),
    );
  }
}
