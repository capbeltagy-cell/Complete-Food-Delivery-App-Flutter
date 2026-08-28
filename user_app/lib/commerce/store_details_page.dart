import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dierb_core/dierb_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/dierb_states.dart';
import 'cart_controller.dart';
import 'modern_cart_page.dart';

class StoreDetailsPage extends StatelessWidget {
  const StoreDetailsPage({super.key, required this.storeId, required this.store});
  final String storeId;
  final Map<String, dynamic> store;

  bool _addToCart(BuildContext context, Store parsed, Product product) {
    final ownerId = parsed.ownerId.isNotEmpty ? parsed.ownerId : storeId;
    final added = context.read<CartController>().add(
          targetStoreId: storeId,
          targetMerchantId: ownerId,
          targetStoreName: parsed.name,
          line: CartLine(
            productId: product.id,
            name: product.name,
            price: product.effectivePrice,
            quantity: 1,
            image: product.images.isEmpty ? '' : product.images.first,
          ),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(added ? 'تمت الإضافة للسلة' : 'أكمل طلب المتجر الحالي أو امسح السلة أولًا')),
    );
    return added;
  }

  Future<void> _showProduct(BuildContext context, Store parsed, Product product) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 16),
            Container(
              height: 230,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: const Color(0xFFEFF6EE), borderRadius: BorderRadius.circular(20)),
              child: product.images.isEmpty
                  ? const Icon(Icons.inventory_2_outlined, size: 72, color: Color(0xFF166534))
                  : Image.network(product.images.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, size: 64)),
            ),
            const SizedBox(height: 16),
            Text(product.name, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
            if (product.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(product.description, style: const TextStyle(fontSize: 15, height: 1.55)),
            ],
            const SizedBox(height: 14),
            Text('${product.effectivePrice.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Color(0xFF166534))),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: !parsed.isOpen
                  ? null
                  : () {
                      if (_addToCart(context, parsed, product)) Navigator.pop(sheetContext);
                    },
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: Text(parsed.isOpen ? 'إضافة للسلة' : 'المتجر مغلق حاليًا'),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parsed = Store.fromMap(storeId, store);
    final isOpen = parsed.isOpen;
    final cover = parsed.cover ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(parsed.name)),
      floatingActionButton: Consumer<CartController>(
        builder: (_, cart, __) => cart.isEmpty
            ? const SizedBox.shrink()
            : FloatingActionButton.extended(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ModernCartPage())),
                icon: const Icon(Icons.shopping_cart_rounded),
                label: Text('السلة (${cart.count})'),
              ),
      ),
      body: ListView(
        children: [
          Container(
            height: 170,
            color: const Color(0xFFE0F2E9),
            child: cover.isEmpty
                ? const Icon(Icons.storefront_rounded, size: 72, color: Color(0xFF166534))
                : Image.network(cover, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.storefront_rounded, size: 72)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(parsed.name, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900))),
                Chip(
                  label: Text(isOpen ? 'مفتوح' : 'مغلق'),
                  avatar: Icon(Icons.circle, size: 11, color: isOpen ? Colors.green : Colors.red),
                ),
              ]),
              if (parsed.description.isNotEmpty) Text(parsed.description),
              if (parsed.address.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(parsed.address)),
              if (parsed.displayHours.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text('ساعات العمل: ${parsed.displayHours}')),
              if (parsed.phone.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(parsed.phone)),
              const SizedBox(height: 18),
              const Text('المنتجات', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            ]),
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('products').where('storeId', isEqualTo: storeId).where('available', isEqualTo: true).limit(80).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: DierbMessage(icon: Icons.cloud_off_rounded, title: firestoreErrorMessage(snapshot.error!)),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
              }
              final docs = snapshot.data!.docs.where((doc) => Product.fromMap(doc.id, doc.data()).available).toList();
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: DierbMessage(
                    icon: Icons.inventory_2_outlined,
                    title: 'لا توجد منتجات متاحة حاليًا',
                    subtitle: 'المتجر ظاهر، وهتقدر تطلب أول ما التاجر يضيف منتجات.',
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                itemCount: docs.length,
                itemBuilder: (_, index) {
                  final doc = docs[index];
                  final product = Product.fromMap(doc.id, doc.data());
                  return Card(
                    child: ListTile(
                      leading: SizedBox.square(
                        dimension: 58,
                        child: product.images.isEmpty
                            ? const Icon(Icons.inventory_2_outlined)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(product.images.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined)),
                              ),
                      ),
                      title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(product.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('${product.effectivePrice.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.w900)),
                        const Icon(Icons.add_circle_rounded, color: Color(0xFF166534)),
                      ]),
                      onTap: () => _showProduct(context, parsed, product),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
