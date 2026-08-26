import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StoreSettingsScreen extends StatefulWidget {
  const StoreSettingsScreen({super.key});
  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  final name = TextEditingController();
  final description = TextEditingController();
  final phone = TextEditingController();
  final whatsapp = TextEditingController();
  final address = TextEditingController();
  final openingHours = TextEditingController();
  bool loading = true;
  bool saving = false;
  bool isOpen = false;
  String status = 'pending';

  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (uid.isEmpty) return;
    final snap = await FirebaseFirestore.instance.collection('stores').doc(uid).get();
    final data = snap.data() ?? <String, dynamic>{};
    name.text = data['name']?.toString() ?? '';
    description.text = data['description']?.toString() ?? '';
    phone.text = data['phone']?.toString() ?? '';
    whatsapp.text = data['whatsapp']?.toString() ?? '';
    address.text = data['address']?.toString() ?? '';
    openingHours.text = data['openingHours']?.toString() ?? '';
    isOpen = data['isOpen'] == true;
    status = data['status']?.toString() ?? 'pending';
    if (mounted) setState(() => loading = false);
  }

  Future<void> _save() async {
    if (uid.isEmpty || name.text.trim().isEmpty) return;
    setState(() => saving = true);
    final ref = FirebaseFirestore.instance.collection('stores').doc(uid);
    final exists = (await ref.get()).exists;
    final payload = <String, dynamic>{
      'name': name.text.trim(),
      'description': description.text.trim(),
      'phone': phone.text.trim(),
      'whatsapp': whatsapp.text.trim(),
      'address': address.text.trim(),
      'openingHours': openingHours.text.trim(),
      'isOpen': isOpen,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    try {
      if (exists) {
        await ref.update(payload);
      } else {
        await ref.set({
          ...payload,
          'ownerId': uid,
          'logo': '',
          'cover': '',
          'categoryId': 'general',
          'cityId': 'dierb-nigm',
          'areaId': '',
          'villageId': '',
          'latitude': 0,
          'longitude': 0,
          'deliveryEnabled': true,
          'pickupEnabled': true,
          'deliveryZones': <String>[],
          'minimumOrder': 0,
          'deliveryFee': 0,
          'verified': false,
          'featured': false,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ بيانات المتجر')));
    } on FirebaseException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الحفظ: ${e.code}')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات المتجر', style: TextStyle(fontWeight: FontWeight.w900))),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.verified_user_outlined),
                    title: const Text('حالة المتجر'),
                    subtitle: Text(status == 'approved' ? 'معتمد ويظهر للعملاء' : status == 'rejected' ? 'مرفوض - راجع الإدارة' : status == 'suspended' ? 'موقوف' : 'قيد مراجعة الإدارة'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم المتجر', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'وصف المتجر', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: whatsapp, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'واتساب', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: address, decoration: const InputDecoration(labelText: 'العنوان', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: openingHours, decoration: const InputDecoration(labelText: 'ساعات العمل', hintText: 'مثال: 9 ص - 11 م', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: isOpen,
                  onChanged: status == 'approved' ? (value) => setState(() => isOpen = value) : null,
                  title: const Text('المتجر مفتوح الآن'),
                  subtitle: Text(status == 'approved' ? 'يمكنك فتح وإغلاق المتجر' : 'يتاح بعد موافقة الإدارة'),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(onPressed: saving ? null : _save, icon: const Icon(Icons.save_outlined), label: Text(saving ? 'جاري الحفظ...' : 'حفظ بيانات المتجر')),
              ],
            ),
    );
  }
}
