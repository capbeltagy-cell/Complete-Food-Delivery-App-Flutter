import 'package:dierb_core/dierb_core.dart';
import 'package:flutter/material.dart';

import 'local_listings_page.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});
  @override Widget build(BuildContext context) {
    final categories = LaunchCategoryDefaults.values.where((item) => item.active).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return SafeArea(child: Scaffold(appBar: AppBar(title: const Text('الأقسام', style: TextStyle(fontWeight: FontWeight.w900))), body: GridView.builder(padding: const EdgeInsets.all(14), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.35, crossAxisSpacing: 11, mainAxisSpacing: 11), itemCount: categories.length, itemBuilder: (_, index) {
      final category = categories[index];
      return InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LocalListingsPage(category: category))), borderRadius: BorderRadius.circular(20), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(_icon(category.type), color: const Color(0xFF166534), size: 31), const Spacer(), Text(category.nameAr, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), Text(category.nameEn, style: const TextStyle(fontSize: 11, color: Colors.grey))])));
    })));
  }
  IconData _icon(CategoryType type) { switch (type) { case CategoryType.service: return Icons.handyman_rounded; case CategoryType.property: return Icons.apartment_rounded; case CategoryType.job: return Icons.work_rounded; case CategoryType.directory: return Icons.location_city_rounded; case CategoryType.offer: return Icons.local_offer_rounded; default: return Icons.storefront_rounded; } }
}
