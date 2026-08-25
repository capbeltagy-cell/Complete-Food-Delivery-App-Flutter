import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rider_app/global/global.dart';
import 'package:rider_app/mainScreens/earning_screens.dart';
import 'package:rider_app/mainScreens/history_screen.dart';
import 'package:rider_app/mainScreens/new_orders_screen.dart';
import 'package:rider_app/mainScreens/not_yetDelivered_screen.dart';
import 'package:rider_app/mainScreens/parcel_in_progress.dart';

import '../assistant_methods/get_current_location.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String get riderId => sharedPreferences?.getString('uid') ?? '';
  @override void initState() { super.initState(); UserLocation().getCurrentLocation(); getPerParcelDeliveryAmount(); getRiderPreviousEarnings(); }

  Future<void> _setAvailable(bool available) => FirebaseFirestore.instance.collection('riders').doc(riderId).update(<String, dynamic>{'available': available, 'availabilityUpdatedAt': FieldValue.serverTimestamp()});
  void _open(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  void getRiderPreviousEarnings() => FirebaseFirestore.instance.collection('riders').doc(riderId).get().then((snap) => previousRidersEarnings = snap.data()?['earnings']?.toString() ?? '0');
  void getPerParcelDeliveryAmount() => FirebaseFirestore.instance.collection('appSettings').doc('delivery').get().then((snap) => perParcelDeliveryAmount = snap.data()?['defaultRiderFee']?.toString() ?? '0');

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('ديرب للمندوبين', style: TextStyle(fontWeight: FontWeight.w900)), Text(sharedPreferences?.getString('name') ?? '', style: const TextStyle(fontSize: 12))])),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(stream: FirebaseFirestore.instance.collection('riders').doc(riderId).snapshots(), builder: (_, snapshot) {
        final available = snapshot.data?.data()?['available'] == true;
        return Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(gradient: LinearGradient(colors: available ? const [Color(0xFF14532D), Color(0xFF22A060)] : const [Color(0xFF4B5563), Color(0xFF6B7280)]), borderRadius: BorderRadius.circular(24)), child: Row(children: [Icon(available ? Icons.delivery_dining_rounded : Icons.pause_circle_rounded, color: Colors.white, size: 48), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(available ? 'متاح لاستقبال طلبات' : 'أنت غير متاح الآن', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)), const SizedBox(height: 4), const Text('التعيين يتم حسب منطقة التوصيل', style: TextStyle(color: Colors.white70))])), Switch(value: available, onChanged: _setAvailable)]));
      }),
      const SizedBox(height: 22), const Text('شغلك اليوم', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 12),
      GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, childAspectRatio: 1.15, crossAxisSpacing: 12, mainAxisSpacing: 12, children: [
        _Tile(Icons.assignment_rounded, 'طلبات توصيل متاحة', 'اختار مهمة قريبة', () => _open(const NewOrdersScreen())),
        _Tile(Icons.store_mall_directory_rounded, 'جاري الاستلام', 'توجه للمتجر', () => _open(const ParcelInProgress())),
        _Tile(Icons.route_rounded, 'في الطريق', 'تواصل مع العميل', () => _open(const NotYetDeliveredScreen())),
        _Tile(Icons.history_rounded, 'سجل التوصيل', 'طلباتك السابقة', () => _open(const HistoryScreen())),
        _Tile(Icons.account_balance_wallet_rounded, 'الأرباح', 'راجع مستحقاتك', () => _open(const EarningScreen())),
        _Tile(Icons.map_rounded, 'مناطق العمل', 'مناطق التوصيل', () {}),
      ]),
    ]),
  );
}

class _Tile extends StatelessWidget {
  const _Tile(this.icon, this.title, this.subtitle, this.onTap); final IconData icon; final String title; final String subtitle; final VoidCallback onTap;
  @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: const Color(0xFF166534), size: 31), const Spacer(), Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey))])));
}
