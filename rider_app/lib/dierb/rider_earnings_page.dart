import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dierb_core/dierb_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RiderEarningsPage extends StatelessWidget {
  const RiderEarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('أرباح التوصيل', style: TextStyle(fontWeight: FontWeight.w900))),
      body: uid.isEmpty
          ? const Center(child: Text('سجّل الدخول أولاً'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('orders').where('riderUID', isEqualTo: uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('تعذر تحميل الأرباح\n${snapshot.error}', textAlign: TextAlign.center));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final delivered = snapshot.data!.docs.where((doc) => OrderStatusCodec.fromStorage(doc.data()['status']) == OrderStatus.delivered).toList();
                return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance.collection('appSettings').doc('delivery').get(),
                  builder: (context, feeSnapshot) {
                    final defaultFee = (feeSnapshot.data?.data()?['defaultRiderFee'] as num?)?.toDouble() ?? 0;
                    var total = 0.0;
                    for (final doc in delivered) {
                      total += (doc.data()['riderFee'] as num?)?.toDouble() ?? defaultFee;
                    }
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF14532D), Color(0xFF22A060)]),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('إجمالي الأرباح', style: TextStyle(color: Colors.white70)),
                              const SizedBox(height: 6),
                              Text('${total.toStringAsFixed(2)} ج.م', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 8),
                              Text('${delivered.length} توصيل مكتمل', style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text('التوصيلات المكتملة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        if (delivered.isEmpty)
                          const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('لسه مفيش توصيلات مكتملة'))))
                        else
                          ...delivered.map((doc) {
                            final data = doc.data();
                            final fee = (data['riderFee'] as num?)?.toDouble() ?? defaultFee;
                            return Card(
                              child: ListTile(
                                leading: const CircleAvatar(child: Icon(Icons.check_rounded)),
                                title: Text(data['storeName']?.toString() ?? 'متجر ديرب'),
                                subtitle: Text(data['customerName']?.toString() ?? 'عميل'),
                                trailing: Text('${fee.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.w900)),
                              ),
                            );
                          }),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}
