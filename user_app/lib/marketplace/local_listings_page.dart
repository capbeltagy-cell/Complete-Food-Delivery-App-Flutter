import 'package:dierb_api_client/dierb_api_client.dart';
import 'package:dierb_core/dierb_core.dart';
import 'package:flutter/material.dart';
import '../commerce/store_details_page.dart';

class LocalListingsPage extends StatefulWidget {
  const LocalListingsPage({super.key, required this.category});
  final Category category;
  @override State<LocalListingsPage> createState() => _LocalListingsPageState();
}

class _LocalListingsPageState extends State<LocalListingsPage> {
  final api = DierbApi();
  late Future<List<dynamic>> request = _load();

  Future<List<dynamic>> _load() {
    if (widget.category.type != CategoryType.store) return Future.value(const []);
    return api.stores(categoryId: widget.category.id);
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.category.nameAr)),
    body: FutureBuilder<List<dynamic>>(future: request, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return _Empty(message: 'تعذر تحميل البيانات الآن.', onRetry: () => setState(() => request = _load()));
      final rows = snapshot.data ?? const [];
      if (rows.isEmpty) return const _Empty();
      return RefreshIndicator(
        onRefresh: () async { setState(() => request = _load()); await request; },
        child: ListView.separated(
          padding: const EdgeInsets.all(14), itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 9),
          itemBuilder: (_, index) {
            final data = Map<String, dynamic>.from(rows[index] as Map);
            final id = data['id'].toString();
            final logo = (data['logoUrl'] ?? '').toString();
            return Card(child: ListTile(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoreDetailsPage(storeId: id, store: data))),
              leading: CircleAvatar(backgroundImage: logo.isEmpty ? null : NetworkImage(logo), child: logo.isEmpty ? const Icon(Icons.storefront_rounded) : null),
              title: Text(data['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(data['description']?.toString() ?? ''),
              trailing: const Icon(Icons.chevron_left_rounded),
            ));
          },
        ),
      );
    }),
  );

  @override void dispose() { api.close(); super.dispose(); }
}

class _Empty extends StatelessWidget {
  const _Empty({this.message = 'لا توجد نتائج في منطقتك حاليًا', this.onRetry});
  final String message; final VoidCallback? onRetry;
  @override Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.search_off_rounded, size: 56, color: Colors.grey), const SizedBox(height: 10), Text(message),
    if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
  ]));
}
