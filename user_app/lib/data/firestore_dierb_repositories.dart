import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dierb_core/dierb_core.dart';

class FirestoreLocationRepository implements LocationRepository {
  FirestoreLocationRepository(this.firestore);
  final FirebaseFirestore firestore;

  @override
  Future<List<City>> activeCities() async {
    final result = await firestore.collection('cities').where('active', isEqualTo: true).orderBy('sortOrder').get();
    return result.docs.map((doc) => City.fromMap(doc.id, doc.data())).toList(growable: false);
  }

  @override
  Future<List<Area>> areasForCity(String cityId) async {
    final result = await firestore.collection('areas').where('cityId', isEqualTo: cityId).where('active', isEqualTo: true).orderBy('nameAr').get();
    return result.docs.map((doc) => Area.fromMap(doc.id, doc.data())).toList(growable: false);
  }

  @override
  Future<List<Village>> villagesForCity(String cityId, {String? areaId}) async {
    Query<Map<String, dynamic>> query = firestore.collection('villages').where('cityId', isEqualTo: cityId).where('active', isEqualTo: true);
    if (areaId != null) query = query.where('areaId', isEqualTo: areaId);
    final result = await query.orderBy('nameAr').get();
    return result.docs.map((doc) => Village.fromMap(doc.id, doc.data())).toList(growable: false);
  }

  @override
  Future<List<ServiceZone>> zonesForLocation(LocationRef location) async {
    final result = await firestore.collection('serviceZones').where('cityId', isEqualTo: location.cityId).where('active', isEqualTo: true).get();
    return result.docs.map((doc) => ServiceZone.fromMap(doc.id, doc.data())).where((zone) {
      final areaMatches = location.areaId == null || zone.areaIds.isEmpty || zone.areaIds.contains(location.areaId);
      final villageMatches = location.villageId == null || zone.villageIds.isEmpty || zone.villageIds.contains(location.villageId);
      return areaMatches && villageMatches;
    }).toList(growable: false);
  }
}

class FirestoreCategoryRepository implements CategoryRepository {
  FirestoreCategoryRepository(this.firestore);
  final FirebaseFirestore firestore;

  @override
  Future<List<Category>> activeCategories({CategoryType? type, bool? featured}) async {
    Query<Map<String, dynamic>> query = firestore.collection('categories').where('active', isEqualTo: true);
    if (type != null) query = query.where('type', isEqualTo: type.name);
    if (featured != null) query = query.where('featured', isEqualTo: featured);
    final result = await query.orderBy('sortOrder').get();
    return result.docs.map((doc) => Category.fromMap(doc.id, doc.data())).toList(growable: false);
  }
}

class FirestoreStoreRepository implements StoreRepository {
  FirestoreStoreRepository(this.firestore);
  final FirebaseFirestore firestore;

  @override
  Future<Store?> byId(String storeId) async {
    final doc = await firestore.collection('stores').doc(storeId).get();
    return doc.exists ? Store.fromMap(doc.id, doc.data()!) : null;
  }

  @override
  Future<PageResult<Store>> discoverApprovedStores(LocationRef location, PageRequest page, {String? categoryId}) async {
    Query<Map<String, dynamic>> query = firestore
        .collection('stores')
        .where('status', isEqualTo: MerchantStatus.approved.name)
        .where('cityId', isEqualTo: location.cityId);
    if (location.areaId != null) query = query.where('areaId', isEqualTo: location.areaId);
    if (location.villageId != null) query = query.where('villageId', isEqualTo: location.villageId);
    if (categoryId != null) query = query.where('categoryId', isEqualTo: categoryId);
    query = query.orderBy('featured', descending: true).orderBy(FieldPath.documentId).limit(page.limit);
    if (page.cursor is DocumentSnapshot<Map<String, dynamic>>) {
      query = query.startAfterDocument(page.cursor! as DocumentSnapshot<Map<String, dynamic>>);
    }
    final result = await query.get();
    return PageResult<Store>(
      items: result.docs.map((doc) => Store.fromMap(doc.id, doc.data())).toList(growable: false),
      nextCursor: result.docs.isEmpty ? null : result.docs.last,
      hasMore: result.docs.length == page.limit,
    );
  }
}

class FirestoreProductRepository implements ProductRepository {
  FirestoreProductRepository(this.firestore);
  final FirebaseFirestore firestore;

  @override
  Future<PageResult<Product>> productsForStore(String storeId, PageRequest page, {String? categoryId}) async {
    Query<Map<String, dynamic>> query = firestore.collection('products').where('storeId', isEqualTo: storeId).where('available', isEqualTo: true);
    if (categoryId != null) query = query.where('categoryId', isEqualTo: categoryId);
    query = query.orderBy('featured', descending: true).orderBy(FieldPath.documentId).limit(page.limit);
    if (page.cursor is DocumentSnapshot<Map<String, dynamic>>) {
      query = query.startAfterDocument(page.cursor! as DocumentSnapshot<Map<String, dynamic>>);
    }
    final result = await query.get();
    return PageResult<Product>(
      items: result.docs.map((doc) => Product.fromMap(doc.id, doc.data())).toList(growable: false),
      nextCursor: result.docs.isEmpty ? null : result.docs.last,
      hasMore: result.docs.length == page.limit,
    );
  }
}
