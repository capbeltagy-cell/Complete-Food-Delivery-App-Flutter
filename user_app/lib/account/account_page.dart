import 'package:dierb_api_client/dierb_api_client.dart';
import 'package:flutter/material.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final api = DierbApi();
  late Future<Map<String, dynamic>?> account = _load();

  Future<Map<String, dynamic>?> _load() async {
    if (!await api.hasSession) return null;
    try { return await api.profile(); }
    on DierbApiException catch (error) { if (error.statusCode == 401) return null; rethrow; }
  }
  void refresh() => setState(() => account = _load());

  @override Widget build(BuildContext context) => SafeArea(child: Scaffold(
    appBar: AppBar(title: const Text('حسابي', style: TextStyle(fontWeight: FontWeight.w900))),
    body: FutureBuilder<Map<String, dynamic>?>(future: account, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return _AccountError(onRetry: refresh, message: _message(snapshot.error));
      return snapshot.data == null ? _GuestAccount(onChanged: refresh) : _SignedInAccount(api: api, profile: snapshot.data!, onChanged: refresh);
    }),
  ));

  @override void dispose() { api.close(); super.dispose(); }
}

class _GuestAccount extends StatelessWidget {
  const _GuestAccount({required this.onChanged});
  final VoidCallback onChanged;
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    const SizedBox(height: 34),
    const CircleAvatar(radius: 42, child: Icon(Icons.person_outline_rounded, size: 44)),
    const SizedBox(height: 18),
    const Text('أهلاً بيك في ديرب', textAlign: TextAlign.center, style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
    const SizedBox(height: 8),
    const Text('تقدر تتصفح كضيف، وسجّل الدخول للطلب والمشاركة مع أهل ديرب.', textAlign: TextAlign.center),
    const SizedBox(height: 24),
    FilledButton(onPressed: () => _showAuth(context, register: false, onChanged: onChanged), child: const Text('تسجيل الدخول')),
    const SizedBox(height: 10),
    OutlinedButton(onPressed: () => _showAuth(context, register: true, onChanged: onChanged), child: const Text('إنشاء حساب جديد')),
  ]);
}

Future<void> _showAuth(BuildContext context, {required bool register, required VoidCallback onChanged}) async {
  final changed = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => _AuthSheet(register: register));
  if (changed == true) onChanged();
}

class _AuthSheet extends StatefulWidget {
  const _AuthSheet({required this.register});
  final bool register;
  @override State<_AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<_AuthSheet> {
  final api = DierbApi();
  final name = TextEditingController(), phone = TextEditingController(), email = TextEditingController(), password = TextEditingController();
  late bool register = widget.register;
  bool saving = false;
  String? error;

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.length < 10 || (register && name.text.trim().length < 2)) {
      setState(() => error = 'راجع البيانات وكلمة المرور لازم تكون 10 حروف على الأقل.'); return;
    }
    setState(() { saving = true; error = null; });
    try {
      if (register) {
        await api.register(email: email.text.trim(), password: password.text, name: name.text.trim(), phone: phone.text.trim());
      } else {
        await api.login(email.text.trim(), password.text, deviceName: 'customer-app');
      }
      if (mounted) Navigator.pop(context, true);
    } catch (exception) {
      if (mounted) setState(() { saving = false; error = _message(exception); });
    }
  }

  @override Widget build(BuildContext context) => Padding(padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.viewInsetsOf(context).bottom + 20), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Text(register ? 'إنشاء حساب' : 'تسجيل الدخول', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
    const SizedBox(height: 16),
    if (register) ...[
      TextField(controller: name, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'الاسم', prefixIcon: Icon(Icons.person_outline))),
      TextField(controller: phone, keyboardType: TextInputType.phone, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone_outlined))),
    ],
    TextField(controller: email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email_outlined))),
    TextField(controller: password, obscureText: true, onSubmitted: (_) => submit(), decoration: const InputDecoration(labelText: 'كلمة المرور', prefixIcon: Icon(Icons.lock_outline))),
    if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
    const SizedBox(height: 18),
    FilledButton(onPressed: saving ? null : submit, child: saving ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(register ? 'إنشاء الحساب' : 'دخول')),
    TextButton(onPressed: saving ? null : () => setState(() { register = !register; error = null; }), child: Text(register ? 'عندي حساب بالفعل' : 'إنشاء حساب جديد')),
  ])));
  @override void dispose() { api.close(); name.dispose(); phone.dispose(); email.dispose(); password.dispose(); super.dispose(); }
}

class _SignedInAccount extends StatelessWidget {
  const _SignedInAccount({required this.api, required this.profile, required this.onChanged});
  final DierbApi api;
  final Map<String, dynamic> profile;
  final VoidCallback onChanged;
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [
      const CircleAvatar(radius: 32, child: Icon(Icons.person_rounded, size: 34)), const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(profile['name']?.toString() ?? 'مستخدم ديرب', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)), Text(profile['email']?.toString() ?? ''), if ((profile['phone'] ?? '').toString().isNotEmpty) Text(profile['phone'].toString())])),
      IconButton(onPressed: () => _editProfile(context), icon: const Icon(Icons.edit_outlined)),
    ]))),
    ListTile(leading: const Icon(Icons.location_on_outlined), title: const Text('عناويني'), subtitle: const Text('إدارة عناوين التوصيل'), onTap: () => _addresses(context)),
    const Divider(),
    ListTile(leading: const Icon(Icons.logout_rounded), title: const Text('تسجيل الخروج'), onTap: () async { await api.logout(); onChanged(); }),
  ]);

  Future<void> _editProfile(BuildContext context) async {
    final name = TextEditingController(text: profile['name']?.toString() ?? '');
    final phone = TextEditingController(text: profile['phone']?.toString() ?? '');
    final saved = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, useSafeArea: true, builder: (sheetContext) => Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(sheetContext).bottom + 20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('تعديل بياناتي', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
      TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم')),
      TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'الهاتف')),
      const SizedBox(height: 16), FilledButton(onPressed: () async { try { await api.updateProfile({'name': name.text.trim(), if (phone.text.trim().isNotEmpty) 'phone': phone.text.trim()}); if (sheetContext.mounted) Navigator.pop(sheetContext, true); } catch (e) { if (sheetContext.mounted) ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(content: Text(_message(e)))); } }, child: const Text('حفظ')),
    ])));
    if (saved == true) onChanged();
  }

  Future<void> _addresses(BuildContext context) async {
    await showModalBottomSheet<void>(context: context, useSafeArea: true, isScrollControlled: true, builder: (_) => _AddressesSheet(api: api));
  }
}

class _AddressesSheet extends StatelessWidget {
  const _AddressesSheet({required this.api}); final DierbApi api;
  @override Widget build(BuildContext context) => FutureBuilder<List<dynamic>>(future: api.addresses(), builder: (context, snapshot) => Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Text('عناوين التوصيل', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)), const SizedBox(height: 12),
    if (snapshot.connectionState != ConnectionState.done) const Expanded(child: Center(child: CircularProgressIndicator()))
    else if (snapshot.hasError) Expanded(child: _AccountError(message: _message(snapshot.error), onRetry: () => Navigator.pop(context)))
    else if ((snapshot.data ?? []).isEmpty) const Expanded(child: Center(child: Text('لا توجد عناوين محفوظة. أضف العنوان أثناء إتمام الطلب.')))
    else Expanded(child: ListView(children: snapshot.data!.map((raw) { final a = raw as Map<String, dynamic>; return Card(child: ListTile(leading: Icon(a['isDefault'] == true ? Icons.home_rounded : Icons.location_on_outlined), title: Text(a['label']?.toString() ?? 'عنوان'), subtitle: Text(a['addressLine']?.toString() ?? ''))); }).toList())),
  ])));
}

class _AccountError extends StatelessWidget {
  const _AccountError({required this.message, required this.onRetry}); final String message; final VoidCallback onRetry;
  @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_rounded, size: 48), const SizedBox(height: 12), Text(message, textAlign: TextAlign.center), const SizedBox(height: 12), OutlinedButton(onPressed: onRetry, child: const Text('إعادة المحاولة'))])));
}

String _message(Object? error) {
  if (error is DierbApiException) {
    if (error.statusCode == 401) return 'انتهت الجلسة. سجل الدخول مرة أخرى.';
    if (error.statusCode == 409) return 'هذه البيانات مستخدمة في حساب آخر.';
    if (error.statusCode == 429) return 'محاولات كثيرة. انتظر قليلًا ثم حاول.';
    if (error.statusCode == 0) return 'تعذر الاتصال بخادم ديرب. تحقق من الإنترنت.';
    return error.message;
  }
  return 'حدث خطأ غير متوقع. حاول مرة أخرى.';
}
