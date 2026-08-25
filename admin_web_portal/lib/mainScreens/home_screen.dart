import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _Section {
  const _Section(this.label, this.icon, this.collection, {this.approval = false});
  final String label; final IconData icon; final String? collection; final bool approval;
}

class _HomeScreenState extends State<HomeScreen> {
  int selected = 0;
  static const sections = <_Section>[
    _Section('لوحة التحكم', Icons.dashboard_rounded, null), _Section('المستخدمون', Icons.people_rounded, 'users'),
    _Section('التجار', Icons.badge_rounded, 'sellers', approval: true), _Section('المتاجر', Icons.store_rounded, 'stores', approval: true),
    _Section('المنتجات', Icons.inventory_2_rounded, 'products'), _Section('الأقسام', Icons.category_rounded, 'categories'),
    _Section('الطلبات', Icons.receipt_long_rounded, 'orders'), _Section('المندوبون', Icons.delivery_dining_rounded, 'riders', approval: true),
    _Section('اسأل ديرب', Icons.forum_rounded, 'communityPosts'), _Section('الخدمات', Icons.handyman_rounded, 'services'),
    _Section('العقارات', Icons.apartment_rounded, 'properties'), _Section('الوظائف', Icons.work_rounded, 'jobs'),
    _Section('العروض', Icons.local_offer_rounded, 'offers'), _Section('الإعلانات', Icons.campaign_rounded, 'advertisements'),
    _Section('الاشتراكات', Icons.workspace_premium_rounded, 'subscriptions'), _Section('البلاغات', Icons.flag_rounded, 'reports'),
    _Section('التقييمات', Icons.star_rounded, 'reviews'), _Section('المدن', Icons.location_city_rounded, 'cities'),
    _Section('المناطق', Icons.map_rounded, 'areas'), _Section('القرى', Icons.holiday_village_rounded, 'villages'),
    _Section('مناطق التوصيل', Icons.route_rounded, 'serviceZones'), _Section('إعدادات التطبيق', Icons.settings_rounded, 'appSettings'),
  ];

  @override Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 850;
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة ديرب', style: TextStyle(fontWeight: FontWeight.w900)), actions: [IconButton(onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout_rounded))]),
      drawer: narrow ? Drawer(child: _navigation()) : null,
      body: Row(children: [if (!narrow) SizedBox(width: 250, child: _navigation()), Expanded(child: selected == 0 ? const _Dashboard() : _CollectionPanel(section: sections[selected]))]),
    );
  }

  Widget _navigation() => ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: List.generate(sections.length, (index) => ListTile(selected: selected == index, leading: Icon(sections[index].icon), title: Text(sections[index].label), onTap: () { setState(() => selected = index); if (Navigator.canPop(context)) Navigator.pop(context); })));
}

class _Dashboard extends StatelessWidget {
  const _Dashboard();
  static const metrics = <(String, String, IconData)>[
    ('طلبات اليوم', 'orders', Icons.receipt_long_rounded), ('تجار للمراجعة', 'sellers', Icons.badge_rounded),
    ('متاجر للمراجعة', 'stores', Icons.store_rounded), ('بلاغات مفتوحة', 'reports', Icons.flag_rounded),
  ];
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(24), children: [
    const Text('نظرة عامة', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)), const SizedBox(height: 18),
    Wrap(spacing: 14, runSpacing: 14, children: metrics.map((metric) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection(metric.$2).limit(100).snapshots(),
      builder: (_, snapshot) => Container(width: 250, height: 125, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Row(children: [CircleAvatar(radius: 25, child: Icon(metric.$3)), const SizedBox(width: 13), Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(metric.$1, style: const TextStyle(fontWeight: FontWeight.w800)), Text('${snapshot.data?.docs.length ?? 0}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900))])])),
    )).toList()),
  ]);
}

class _CollectionPanel extends StatelessWidget {
  const _CollectionPanel({required this.section}); final _Section section;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Row(children: [Expanded(child: Text(section.label, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900))), FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.add_rounded), label: const Text('إضافة'))]), const SizedBox(height: 16),
    Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: FirebaseFirestore.instance.collection(section.collection!).limit(50).snapshots(), builder: (context, snapshot) {
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      if (snapshot.data!.docs.isEmpty) return const Center(child: Text('لا توجد بيانات حتى الآن'));
      return ListView.separated(itemCount: snapshot.data!.docs.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (_, index) {
        final doc = snapshot.data!.docs[index]; final data = doc.data(); final title = data['name'] ?? data['sellerName'] ?? data['riderName'] ?? data['title'] ?? doc.id;
        final status = data['status']?.toString() ?? '';
        return Card(child: ListTile(
          title: Text(title.toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(status.isEmpty ? doc.id : 'الحالة: $status'),
          trailing: Wrap(spacing: 5, children: [
            if (section.approval && status != 'approved') IconButton(tooltip: 'قبول', onPressed: () => doc.reference.update(<String, dynamic>{'status': 'approved'}), icon: const Icon(Icons.check_circle_rounded, color: Colors.green)),
            if (section.approval) IconButton(tooltip: 'تعليق', onPressed: () => doc.reference.update(<String, dynamic>{'status': 'suspended'}), icon: const Icon(Icons.block_rounded, color: Colors.red)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert_rounded)),
          ]),
        ));
      });
    })),
  ]));
}
