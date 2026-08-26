import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dierb_core/dierb_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:seller_app/mainScreens/earning_screens.dart';
import 'package:seller_app/mainScreens/history_screen.dart';
import 'package:seller_app/mainScreens/new_orders_screen.dart';
import 'package:seller_app/mainScreens/store_settings_screen.dart';
import 'package:seller_app/uploadScreens.dart/menus_upload_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String get merchantId => FirebaseAuth.instance.currentUser?.uid ?? '';
  Stream<QuerySnapshot<Map<String, dynamic>>> _orders(List<String> statuses) => FirebaseFirestore.instance.collection('orders').where('sellerUID', isEqualTo: merchantId).where('status', whereIn: statuses).snapshots();
  Future<void> _toggleStore(bool value) => FirebaseFirestore.instance.collection('stores').doc(merchantId).update(<String, dynamic>{'isOpen': value, 'updatedAt': FieldValue.serverTimestamp()});
  void _open(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ديرب للتجار', style: TextStyle(fontWeight: FontWeight.w900)), Text('إدارة متجرك وطلباتك', style: TextStyle(fontSize: 12))]),
        actions: [IconButton(onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout_rounded), tooltip: 'تسجيل الخروج')],
      ),
      body: merchantId.isEmpty
          ? const Center(child: Text('سجّل الدخول للمتابعة'))
          : RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: ListView(padding: const EdgeInsets.all(16), children: [
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('stores').doc(merchantId).snapshots(),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data();
                    if (data == null) {
                      return _MissingStoreCard(onTap: () => _open(const StoreSettingsScreen()));
                    }
                    final store = Store.fromMap(merchantId, <String, dynamic>{
                      ...data,
                      'ownerId': merchantId,
                      'name': data['name'] ?? user?.displayName ?? user?.email ?? 'متجرك',
                      'categoryId': data['categoryId'] ?? 'general',
                      'cityId': data['cityId'] ?? LaunchLocationDefaults.cityId,
                    });
                    return _StoreStatusCard(status: store.status, isOpen: store.isOpen, onChanged: store.publiclyDiscoverable ? _toggleStore : null, onSettings: () => _open(const StoreSettingsScreen()));
                  },
                ),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(child: _Metric(title: 'طلبات جديدة', stream: _orders(<String>['normal', OrderStatus.received.name, OrderStatus.waitingMerchantApproval.name]), color: const Color(0xFFFFE8D6))),
                  const SizedBox(width: 10),
                  Expanded(child: _Metric(title: 'طلبات حالية', stream: _orders(<String>[OrderStatus.accepted.name, OrderStatus.preparing.name, OrderStatus.readyForPickup.name, OrderStatus.pickedUpByRider.name, OrderStatus.onTheWay.name]), color: const Color(0xFFE0F2E9))),
                ]),
                const SizedBox(height: 22),
                const Text('إدارة المتجر', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  childAspectRatio: .92,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    _Action(Icons.receipt_long_rounded, 'الطلبات', () => _open(const NewOrdersScreen())),
                    _Action(Icons.inventory_2_rounded, 'المنتجات', () => _open(const MenusUploadScreen())),
                    _Action(Icons.add_box_rounded, 'إضافة منتج', () => _open(const MenusUploadScreen())),
                    _Action(Icons.storefront_rounded, 'المتجر', () => _open(const StoreSettingsScreen())),
                    _Action(Icons.schedule_rounded, 'ساعات العمل', () => _open(const StoreSettingsScreen())),
                    _Action(Icons.bar_chart_rounded, 'المبيعات', () => _open(const HistoryScreen())),
                    _Action(Icons.account_balance_wallet_rounded, 'الأرباح', () => _open(const EarningScreen())),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('الأزرار غير المكتملة تم إخفاؤها من النسخة التشغيلية لحين ربطها بالكامل.', style: TextStyle(fontSize: 12, color: Colors.black54)),
              ]),
            ),
    );
  }
}

class _MissingStoreCard extends StatelessWidget {
  const _MissingStoreCard({required this.onTap});
  final VoidCallback onTap;
  @override Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Row(children: [CircleAvatar(backgroundColor: Color(0xFFE0F2E9), child: Icon(Icons.storefront_rounded, color: Color(0xFF166534))), SizedBox(width: 12), Expanded(child: Text('جهّز بيانات متجرك', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)))]),
        const SizedBox(height: 8),
        const Text('أضف اسم المتجر والعنوان والهاتف وساعات العمل، وبعد موافقة الإدارة سيظهر للعملاء.'),
        const SizedBox(height: 12),
        FilledButton(onPressed: onTap, child: const Text('إعداد المتجر')),
      ]),
    ),
  );
}

class _StoreStatusCard extends StatelessWidget {
  const _StoreStatusCard({required this.status, required this.isOpen, required this.onSettings, this.onChanged});
  final MerchantStatus status; final bool isOpen; final ValueChanged<bool>? onChanged; final VoidCallback onSettings;
  @override Widget build(BuildContext context) {
    const labels = <MerchantStatus, String>{MerchantStatus.pending: 'طلبك قيد المراجعة', MerchantStatus.approved: 'متجرك معتمد', MerchantStatus.rejected: 'تم رفض الطلب', MerchantStatus.suspended: 'الحساب موقوف'};
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Column(children: [
        Row(children: [
          const CircleAvatar(radius: 27, backgroundColor: Color(0xFFE0F2E9), child: Icon(Icons.store_rounded, color: Color(0xFF166534))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(labels[status]!, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 4), Text(status == MerchantStatus.approved ? (isOpen ? 'مفتوح ويستقبل طلبات' : 'مغلق مؤقتًا') : 'لن يظهر المتجر للعامة قبل موافقة الإدارة')])),
          Switch(value: isOpen, onChanged: onChanged),
        ]),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: onSettings, icon: const Icon(Icons.settings_outlined), label: const Text('تعديل بيانات المتجر'))),
      ]),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.title, required this.stream, required this.color}); final String title; final Stream<QuerySnapshot<Map<String, dynamic>>> stream; final Color color;
  @override Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: stream, builder: (_, snapshot) => Container(height: 105, padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const Spacer(), Text('${snapshot.data?.docs.length ?? 0}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900))])));
}

class _Action extends StatelessWidget {
  const _Action(this.icon, this.label, this.onTap); final IconData icon; final String label; final VoidCallback onTap;
  @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: const Color(0xFF166534), size: 30), const SizedBox(height: 8), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700))])));
}
