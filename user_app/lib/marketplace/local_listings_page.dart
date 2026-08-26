import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dierb_core/dierb_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../commerce/store_details_page.dart';

class LocalListingsPage extends StatelessWidget {
  const LocalListingsPage({super.key, required this.category}); final Category category;
  String get collection { switch (category.type) { case CategoryType.service: return 'services'; case CategoryType.property: return 'properties'; case CategoryType.job: return 'jobs'; case CategoryType.directory: return 'directoryEntries'; case CategoryType.offer: return 'offers'; default: return 'stores'; } }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(category.nameAr)), body: Firebase.apps.isEmpty ? const _Empty() : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: FirebaseFirestore.instance.collection(collection).where('status', isEqualTo: category.type == CategoryType.store ? 'approved' : 'published').limit(50).snapshots(), builder: (_, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
    final docs = (snapshot.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[]).where((doc) {
      final data = doc.data();
      if (data['cityId'] != LaunchLocationDefaults.cityId) return false;
      return category.type != CategoryType.store || data['categoryId'] == category.id;
    }).toList();
    if (docs.isEmpty) return const _Empty();
    return ListView.separated(padding: const EdgeInsets.all(14), itemCount: docs.length, separatorBuilder: (_, __) => const SizedBox(height: 9), itemBuilder: (_, index) { final data = docs[index].data(); final title = data['name'] ?? data['title'] ?? data['employer'] ?? ''; final phone = data['phone']?.toString() ?? ''; return Card(child: ListTile(onTap: category.type == CategoryType.store ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoreDetailsPage(storeId: docs[index].id, store: data))) : null, leading: CircleAvatar(backgroundImage: (data['logo'] ?? '').toString().isEmpty ? null : NetworkImage(data['logo'].toString()), child: (data['logo'] ?? '').toString().isEmpty ? const Icon(Icons.storefront_rounded) : null), title: Text(title.toString(), style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(data['description']?.toString() ?? ''), trailing: category.type == CategoryType.store ? const Icon(Icons.chevron_left_rounded) : phone.isEmpty ? null : IconButton(onPressed: () => launchUrl(Uri.parse('tel:$phone')), icon: const Icon(Icons.phone_rounded)))); });
  }));
}
class _Empty extends StatelessWidget { const _Empty(); @override Widget build(BuildContext context) => const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.search_off_rounded, size: 56, color: Colors.grey), SizedBox(height: 10), Text('لا توجد نتائج في منطقتك حاليًا') ])); }
