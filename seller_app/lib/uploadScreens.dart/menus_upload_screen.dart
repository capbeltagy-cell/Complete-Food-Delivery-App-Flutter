import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MenusUploadScreen extends StatelessWidget {
  const MenusUploadScreen({super.key});

  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) return const Scaffold(body: Center(child: Text('سجّل الدخول كتاجر أولاً')));
    return Scaffold(
      appBar: AppBar(
        title: const Text('منتجات المتجر', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [IconButton(onPressed: () => _openEditor(context), icon: const Icon(Icons.add_rounded), tooltip: 'إضافة منتج')],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _openEditor(context), icon: const Icon(Icons.add_rounded), label: const Text('إضافة منتج')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('products').where('ownerId', isEqualTo: uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('تعذر تحميل المنتجات. حاول مرة أخرى.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs.toList();
          if (docs.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.inventory_2_outlined, size: 70, color: Color(0xFF166534)),
              const SizedBox(height: 12),
              const Text('لسه مفيش منتجات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('أضف أول منتج وهيظهر للعملاء بعد اعتماد المتجر.'),
              const SizedBox(height: 16),
              FilledButton.icon(onPressed: () => _openEditor(context), icon: const Icon(Icons.add), label: const Text('إضافة أول منتج')),
            ]));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final images = (data['images'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
              final price = (data['price'] as num?)?.toDouble() ?? 0;
              final sale = (data['salePrice'] as num?)?.toDouble();
              final available = data['available'] == true;
              return Card(
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: images.isEmpty ? const SizedBox(width: 56, height: 56, child: Icon(Icons.image_outlined)) : Image.network(images.first, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(width: 56, height: 56, child: Icon(Icons.broken_image_outlined))),
                  ),
                  title: Text(data['name']?.toString() ?? 'منتج', style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${sale != null && sale > 0 ? sale : price} ج.م • ${available ? 'متاح' : 'موقوف'}'),
                  onTap: () => _openEditor(context, doc: doc),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'toggle') {
                        await doc.reference.update({'available': !available, 'updatedAt': FieldValue.serverTimestamp()});
                      } else if (value == 'edit') {
                        if (context.mounted) _openEditor(context, doc: doc);
                      } else if (value == 'delete') {
                        await doc.reference.delete();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                      PopupMenuItem(value: 'toggle', child: Text(available ? 'إيقاف المنتج' : 'تفعيل المنتج')),
                      const PopupMenuItem(value: 'delete', child: Text('حذف')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openEditor(BuildContext context, {QueryDocumentSnapshot<Map<String, dynamic>>? doc}) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _ProductEditor(existing: doc)));
  }
}

class _ProductEditor extends StatefulWidget {
  const _ProductEditor({this.existing});
  final QueryDocumentSnapshot<Map<String, dynamic>>? existing;
  @override
  State<_ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends State<_ProductEditor> {
  final name = TextEditingController();
  final description = TextEditingController();
  final price = TextEditingController();
  final salePrice = TextEditingController();
  final stock = TextEditingController(text: '0');
  final categoryId = TextEditingController(text: 'general');
  final imageUrl = TextEditingController();
  bool available = true;
  bool saving = false;

  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    final data = widget.existing?.data();
    if (data != null) {
      name.text = data['name']?.toString() ?? '';
      description.text = data['description']?.toString() ?? '';
      price.text = (data['price'] as num?)?.toString() ?? '';
      salePrice.text = (data['salePrice'] as num?)?.toString() ?? '';
      stock.text = (data['stock'] as num?)?.toString() ?? '0';
      categoryId.text = data['categoryId']?.toString() ?? 'general';
      available = data['available'] == true;
      final images = (data['images'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
      imageUrl.text = images.isEmpty ? '' : images.first;
    }
  }

  Future<void> _save() async {
    final parsedPrice = double.tryParse(price.text.trim());
    if (name.text.trim().isEmpty || parsedPrice == null || parsedPrice < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب اسم وسعر صحيح للمنتج')));
      return;
    }
    setState(() => saving = true);
    final ref = widget.existing?.reference ?? FirebaseFirestore.instance.collection('products').doc();
    try {
      final image = imageUrl.text.trim();
      final payload = <String, dynamic>{
        'name': name.text.trim(),
        'description': description.text.trim(),
        'images': image.isEmpty ? <String>[] : <String>[image],
        'price': parsedPrice,
        'salePrice': double.tryParse(salePrice.text.trim()) ?? 0,
        'stock': int.tryParse(stock.text.trim()) ?? 0,
        'categoryId': categoryId.text.trim().isEmpty ? 'general' : categoryId.text.trim(),
        'options': <Map<String, dynamic>>[],
        'available': available,
        'deliveryEligible': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (widget.existing == null) {
        await ref.set({
          ...payload,
          'productId': ref.id,
          'ownerId': uid,
          'storeId': uid,
          'cityId': 'dierb-nigm',
          'featured': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await ref.update(payload);
      }
      if (mounted) Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر حفظ المنتج: ${e.code}')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewUrl = imageUrl.text.trim();
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'إضافة منتج' : 'تعديل المنتج', style: const TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          height: 180,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: const Color(0xFFEFF6EE), borderRadius: BorderRadius.circular(18)),
          child: previewUrl.isEmpty
              ? const Center(child: Icon(Icons.image_outlined, size: 58, color: Color(0xFF166534)))
              : Image.network(previewUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined, size: 54))),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: imageUrl,
          onChanged: (_) => setState(() {}),
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(labelText: 'رابط صورة المنتج (اختياري)', hintText: 'https://...', border: OutlineInputBorder(), helperText: 'رفع الصور المباشر مؤجل حاليًا؛ المنتج يُحفظ ويعمل بدون صورة.'),
        ),
        const SizedBox(height: 14),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم المنتج', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'الوصف', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعر', border: OutlineInputBorder()))),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: salePrice, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر العرض', border: OutlineInputBorder()))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المخزون', border: OutlineInputBorder()))),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: categoryId, decoration: const InputDecoration(labelText: 'كود القسم', border: OutlineInputBorder()))),
        ]),
        SwitchListTile(value: available, onChanged: (v) => setState(() => available = v), title: const Text('المنتج متاح للعملاء')),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: saving ? null : _save, icon: const Icon(Icons.save_outlined), label: Text(saving ? 'جاري الحفظ...' : 'حفظ المنتج')),
      ]),
    );
  }
}
