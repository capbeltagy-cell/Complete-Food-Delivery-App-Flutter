import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_controller.dart';
import 'modern_cart_page.dart';

class StoreDetailsPage extends StatelessWidget {
  const StoreDetailsPage({super.key, required this.storeId, required this.store});
  final String storeId;
  final Map<String, dynamic> store;

  @override
  Widget build(BuildContext context) {
    final isOpen = store['isOpen'] == true;
    return Scaffold(
      appBar: AppBar(title: Text((store['name'] ?? 'المتجر').toString())),
      floatingActionButton: Consumer<CartController>(builder: (_, cart, __) => cart.isEmpty ? const SizedBox.shrink() : FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ModernCartPage())),
        icon: const Icon(Icons.shopping_cart_rounded), label: Text('السلة (${cart.count})'),
      )),
      body: ListView(children: [
        Container(height: 170, color: const Color(0xFFE0F2E9), child: (store['cover'] ?? '').toString().isEmpty ? const Icon(Icons.storefront_rounded, size: 72, color: Color(0xFF166534)) : Image.network(store['cover'].toString(), fit: BoxFit.cover)),
        Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text((store['name'] ?? '').toString(), style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900))), Chip(label: Text(isOpen ? 'مفتوح' : 'مغلق'), avatar: Icon(Icons.circle, size: 11, color: isOpen ? Colors.green : Colors.red))]),
          if ((store['description'] ?? '').toString().isNotEmpty) Text(store['description'].toString()),
          const SizedBox(height: 18), const Text('المنتجات', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        ])),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('products').where('storeId', isEqualTo: storeId).where('available', isEqualTo: true).limit(50).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Padding(padding: const EdgeInsets.all(20), child: Text('تعذر تحميل المنتجات: ${snapshot.error}'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            if (snapshot.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('لا توجد منتجات متاحة حاليًا')));
            return ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(12, 0, 12, 100), itemCount: snapshot.data!.docs.length, itemBuilder: (_, index) {
              final doc = snapshot.data!.docs[index]; final data = doc.data();
              final price = ((data['salePrice'] ?? data['price'] ?? 0) as num).toDouble();
              final images = (data['images'] as List?)?.cast<String>() ?? const <String>[];
              return Card(child: ListTile(
                leading: SizedBox.square(dimension: 58, child: images.isEmpty ? const Icon(Icons.inventory_2_outlined) : ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(images.first, fit: BoxFit.cover))),
                title: Text((data['name'] ?? 'منتج').toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text((data['description'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('${price.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.w900)), const Icon(Icons.add_circle_rounded, color: Color(0xFF166534))]),
                onTap: !isOpen ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('المتجر مغلق حاليًا'))) : () {
                  final added = context.read<CartController>().add(targetStoreId: storeId, targetMerchantId: (store['ownerId'] ?? '').toString(), targetStoreName: (store['name'] ?? '').toString(), line: CartLine(productId: doc.id, name: (data['name'] ?? 'منتج').toString(), price: price, quantity: 1, image: images.isEmpty ? '' : images.first));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(added ? 'تمت الإضافة للسلة' : 'أكمل طلب المتجر الحالي أو امسح السلة أولًا')));
                },
              ));
            });
          },
        ),
      ]),
    );
  }
}
