import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../authentication/login.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _Section {
  const _Section(this.label, this.icon, this.collection, {this.approval = false});
  final String label;
  final IconData icon;
  final String? collection;
  final bool approval;
}

class _HomeScreenState extends State<HomeScreen> {
  int selected = 0;
  static const sections = <_Section>[
    _Section('لوحة التحكم', Icons.dashboard_rounded, null),
    _Section('المستخدمون', Icons.people_rounded, 'users'),
    _Section('طلبات التجار', Icons.badge_rounded, 'merchantApplications', approval: true),
    _Section('المتاجر', Icons.store_rounded, 'stores', approval: true),
    _Section('المنتجات', Icons.inventory_2_rounded, 'products'),
    _Section('الأقسام', Icons.category_rounded, 'categories'),
    _Section('الطلبات', Icons.receipt_long_rounded, 'orders'),
    _Section('المندوبون', Icons.delivery_dining_rounded, 'riders', approval: true),
    _Section('اسأل ديرب', Icons.forum_rounded, 'communityPosts'),
    _Section('الخدمات', Icons.handyman_rounded, 'services'),
    _Section('العقارات', Icons.apartment_rounded, 'properties'),
    _Section('الوظائف', Icons.work_rounded, 'jobs'),
    _Section('العروض', Icons.local_offer_rounded, 'offers'),
    _Section('البلاغات', Icons.flag_rounded, 'reports'),
    _Section('التقييمات', Icons.star_rounded, 'reviews'),
    _Section('المدن', Icons.location_city_rounded, 'cities'),
    _Section('المناطق', Icons.map_rounded, 'areas'),
    _Section('القرى', Icons.holiday_village_rounded, 'villages'),
    _Section('مناطق التوصيل', Icons.route_rounded, 'serviceZones'),
    _Section('إعدادات التطبيق', Icons.settings_rounded, 'appSettings'),
  ];

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 850;
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة ديرب', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout_rounded), tooltip: 'تسجيل الخروج')],
      ),
      drawer: narrow ? Drawer(child: _navigation()) : null,
      body: Row(children: [
        if (!narrow) SizedBox(width: 250, child: _navigation()),
        Expanded(child: selected == 0 ? const _Dashboard() : _CollectionPanel(section: sections[selected])),
      ]),
    );
  }

  Widget _navigation() => ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: List.generate(
          sections.length,
          (index) => ListTile(
            selected: selected == index,
            leading: Icon(sections[index].icon),
            title: Text(sections[index].label),
            onTap: () {
              setState(() => selected = index);
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
          ),
        ),
      );
}

class _Dashboard extends StatelessWidget {
  const _Dashboard();
  static const metrics = <(String, String, IconData)>[
    ('الطلبات', 'orders', Icons.receipt_long_rounded),
    ('تجار للمراجعة', 'merchantApplications', Icons.badge_rounded),
    ('المتاجر', 'stores', Icons.store_rounded),
    ('البلاغات', 'reports', Icons.flag_rounded),
  ];

  @override Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('نظرة عامة', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: metrics
                .map((metric) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance.collection(metric.$2).limit(100).snapshots(),
                      builder: (_, snapshot) => Container(
                        width: 250,
                        height: 125,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: Row(children: [
                          CircleAvatar(radius: 25, child: Icon(metric.$3)),
                          const SizedBox(width: 13),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(metric.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
                              Text('${snapshot.data?.docs.length ?? 0}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ]),
                      ),
                    ))
                .toList(),
          ),
        ],
      );
}

class _CollectionPanel extends StatelessWidget {
  const _CollectionPanel({required this.section});
  final _Section section;

  Future<void> _setStatus(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String status,
  ) async {
    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();
      final now = FieldValue.serverTimestamp();
      batch.update(doc.reference, <String, dynamic>{'status': status, 'updatedAt': now});

      // A merchant application and the merchant store share the owner's uid.
      // Keep both approval states synchronized so the merchant is not forced
      // through two separate admin approval steps.
      if (section.collection == 'merchantApplications') {
        final data = doc.data();
        final ownerId = (data['userId'] ?? doc.id).toString();
        final storeRef = db.collection('stores').doc(ownerId);
        final store = await storeRef.get();
        if (store.exists) {
          batch.update(storeRef, <String, dynamic>{'status': status, 'updatedAt': now});
        }
        final sellerRef = db.collection('sellers').doc(ownerId);
        final seller = await sellerRef.get();
        if (seller.exists) {
          batch.update(sellerRef, <String, dynamic>{'status': status, 'updatedAt': now});
        }
      }

      await batch.commit();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'approved'
                  ? 'تمت الموافقة'
                  : status == 'rejected'
                      ? 'تم الرفض'
                      : 'تم الإيقاف',
            ),
          ),
        );
      }
    } on FirebaseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تنفيذ الإجراء: ${e.code}')));
      }
    }
  }

  @override Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(section.label, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection(section.collection!).limit(100).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('تعذر تحميل ${section.label}: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.docs.isEmpty) return const Center(child: Text('لا توجد بيانات حتى الآن'));
                return ListView.separated(
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data();
                    final title = data['name'] ??
                        data['sellerName'] ??
                        data['riderName'] ??
                        data['customerName'] ??
                        data['title'] ??
                        data['email'] ??
                        doc.id;
                    final status = data['status']?.toString() ?? '';
                    final secondary = data['phone'] ?? data['customerPhone'] ?? data['address'] ?? data['addressText'] ?? '';
                    return Card(
                      child: ListTile(
                        title: Text(title.toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text([
                          if (status.isNotEmpty) 'الحالة: $status',
                          if (secondary.toString().isNotEmpty) secondary.toString(),
                        ].join(' • ')),
                        trailing: section.approval
                            ? Wrap(spacing: 3, children: [
                                if (status != 'approved')
                                  IconButton(
                                    tooltip: 'موافقة',
                                    onPressed: () => _setStatus(context, doc, 'approved'),
                                    icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
                                  ),
                                if (status != 'rejected')
                                  IconButton(
                                    tooltip: 'رفض',
                                    onPressed: () => _setStatus(context, doc, 'rejected'),
                                    icon: const Icon(Icons.cancel_rounded, color: Colors.orange),
                                  ),
                                if (status != 'suspended')
                                  IconButton(
                                    tooltip: 'إيقاف',
                                    onPressed: () => _setStatus(context, doc, 'suspended'),
                                    icon: const Icon(Icons.block_rounded, color: Colors.red),
                                  ),
                              ])
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      );
}
