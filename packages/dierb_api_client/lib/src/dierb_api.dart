import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_exception.dart';
import 'session_store.dart';

class DierbApi {
  DierbApi({DierbApiConfig config = DierbApiConfig.fromEnvironment, http.Client? client, DierbSessionStore? session})
      : _config = config, _client = client ?? http.Client(), _session = session ?? DierbSessionStore();
  final DierbApiConfig _config;
  final http.Client _client;
  final DierbSessionStore _session;
  Future<void>? _refreshing;

  Future<bool> get hasSession => _session.hasSession;
  Future<Map<String, dynamic>> register({required String email, required String password, required String name, String? phone, String role = 'customer'}) async {
    final data = await post('auth/register', {'email': email, 'password': password, 'name': name, if (phone?.isNotEmpty == true) 'phone': phone, 'role': role}, authenticated: false);
    await _saveSession(data); return data;
  }
  Future<Map<String, dynamic>> login(String email, String password, {String? deviceName}) async {
    final data = await post('auth/login', {'email': email, 'password': password, if (deviceName != null) 'deviceName': deviceName}, authenticated: false);
    await _saveSession(data); return data;
  }
  Future<void> logout() async { try { await post('auth/logout', {}); } finally { await _session.clear(); } }
  Future<Map<String, dynamic>> profile() => getMap('account');
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) => patch('account', body);
  Future<Map<String, dynamic>> merchantStore() => getMap('account/merchant/store');
  Future<Map<String, dynamic>> createMerchantStore(Map<String, dynamic> body) => post('account/merchant/store', body);
  Future<Map<String, dynamic>> updateMerchantStore(Map<String, dynamic> body) => patch('account/merchant/store', body);
  Future<Map<String, dynamic>> setRiderAvailability(bool available) => patch('account/rider/availability', {'available': available});
  Future<List<dynamic>> addresses() => getList('account/addresses');
  Future<Map<String, dynamic>> createAddress(Map<String, dynamic> body) => post('account/addresses', body);
  Future<void> deleteAddress(String id) => delete('account/addresses/$id');
  Future<List<dynamic>> categories() => getList('catalog/categories', authenticated: false);
  Future<List<dynamic>> cities() => getList('catalog/cities', authenticated: false);
  Future<List<dynamic>> stores({String? cityId, String? categoryId}) => getList('catalog/stores', query: {if (cityId != null) 'cityId': cityId, if (categoryId != null) 'categoryId': categoryId}, authenticated: false);
  Future<Map<String, dynamic>> store(String id) => getMap('catalog/stores/$id', authenticated: false);
  Future<Map<String, dynamic>> search(String query, {String? cityId}) => getMap('catalog/search', query: {'q': query, if(cityId!=null)'cityId':cityId}, authenticated: false);
  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> body) => post('catalog/products', body);
  Future<Map<String, dynamic>> updateProduct(String id, Map<String, dynamic> body) => patch('catalog/products/$id', body);
  Future<void> archiveProduct(String id) => delete('catalog/products/$id');
  Future<Map<String, dynamic>> setStoreOpen(String id, bool isOpen) => patch('catalog/stores/$id/state', {'isOpen': isOpen});
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> body) => post('orders', body);
  Future<List<dynamic>> orders() => getList('orders');
  Future<List<dynamic>> availableOrders() => getList('orders/available');
  Future<Map<String, dynamic>> claimOrder(String id) => post('orders/$id/claim', {});
  Future<Map<String, dynamic>> transition(String id, String status, {String? note}) => patch('orders/$id/status', {'status': status, if (note != null) 'note': note});
  Future<List<dynamic>> questions({required String cityId, String? cursor}) => getList('community/questions', query: {'cityId': cityId, if (cursor != null) 'cursor': cursor}, authenticated: false);
  Future<Map<String, dynamic>> question(String id) => getMap('community/questions/$id', authenticated: false);
  Future<Map<String, dynamic>> createQuestion(Map<String, dynamic> body) => post('community/questions', body);
  Future<Map<String, dynamic>> answerQuestion(String id, String body) => post('community/questions/$id/answers', {'body': body});
  Future<Map<String, dynamic>> markHelpful(String id) => post('community/questions/$id/helpful', {});
  Future<Map<String, dynamic>> report({required String targetType, required String targetId, required String reason}) => post('community/reports', {'targetType': targetType, 'targetId': targetId, 'reason': reason});
  Future<List<dynamic>> chatMessages(String orderId, {String? cursor}) => getList('orders/$orderId/chat', query: {if (cursor != null) 'cursor': cursor});
  Future<Map<String, dynamic>> sendChatMessage(String orderId, String body, {String type = 'text'}) => post('orders/$orderId/chat', {'body': body, 'type': type});
  Future<List<dynamic>> notifications() => getList('notifications');
  Future<int> unreadNotificationCount() async => ((await getMap('notifications/unread-count'))['count'] as num?)?.toInt() ?? 0;
  Future<Map<String, dynamic>> markNotificationRead(String id) => patch('notifications/$id/read', const {});
  Future<Map<String, dynamic>> markAllNotificationsRead() => patch('notifications/read-all', const {});
  Future<Map<String, dynamic>> adminDashboard() => getMap('admin/dashboard');
  Future<List<dynamic>> adminList(String resource) => getList('admin/$resource');
  Future<Map<String, dynamic>> adminPatch(String path, Map<String, dynamic> body) => patch('admin/$path', body);

  Future<Map<String, dynamic>> uploadImage(List<int> bytes, String filename) async {
    Future<Map<String, dynamic>> send(bool retry) async {
      final token = await _session.accessToken;
      final request = http.MultipartRequest('POST', _config.uri('uploads'))
        ..headers.addAll({'Accept': 'application/json', if (token != null) 'Authorization': 'Bearer $token'})
        ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
      final response = await _client.send(request).timeout(_config.timeout);
      final text = await response.stream.bytesToString();
      if (response.statusCode == 401 && retry) { await _refresh(); return send(false); }
      final decoded = text.isEmpty ? null : jsonDecode(text);
      if (response.statusCode < 200 || response.statusCode >= 300) throw DierbApiException(response.statusCode, decoded is Map ? decoded['message']?.toString() ?? 'Upload failed' : 'Upload failed');
      return Map<String, dynamic>.from(decoded as Map);
    }
    return send(true);
  }

  Future<List<dynamic>> getList(String path, {Map<String, String>? query, bool authenticated = true}) async => (await _request('GET', path, query: query, authenticated: authenticated)) as List<dynamic>;
  Future<Map<String, dynamic>> getMap(String path, {Map<String, String>? query, bool authenticated = true}) async => (await _request('GET', path, query: query, authenticated: authenticated)) as Map<String, dynamic>;
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body, {bool authenticated = true}) async => (await _request('POST', path, body: body, authenticated: authenticated)) as Map<String, dynamic>;
  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async => (await _request('PATCH', path, body: body)) as Map<String, dynamic>;
  Future<void> delete(String path) async { await _request('DELETE', path); }

  Future<dynamic> _request(String method, String path, {Map<String, dynamic>? body, Map<String, String>? query, bool authenticated = true, bool retry = true}) async {
    final token = authenticated ? await _session.accessToken : null;
    try {
      final request = http.Request(method, _config.uri(path, query))
        ..headers.addAll({'Accept': 'application/json', 'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'})
        ..body = body == null ? '' : jsonEncode(body);
      final response = await _client.send(request).timeout(_config.timeout);
      final text = await response.stream.bytesToString();
      if (response.statusCode == 401 && authenticated && retry) { await _refresh(); return _request(method, path, body: body, query: query, authenticated: authenticated, retry: false); }
      final decoded = text.isEmpty ? null : jsonDecode(text);
      if (response.statusCode < 200 || response.statusCode >= 300) throw DierbApiException(response.statusCode, decoded is Map ? (decoded['message']?.toString() ?? 'Server error') : 'Server error', code: decoded is Map ? decoded['code']?.toString() : null);
      return decoded;
    } on DierbApiException { rethrow; }
    catch (error) { throw DierbApiException(0, 'تعذر الاتصال بخادم ديرب', code: error.runtimeType.toString()); }
  }
  Future<void> _refresh() async {
    if (_refreshing != null) return _refreshing;
    final future = () async { final refresh = await _session.refreshToken; if (refresh == null) throw const DierbApiException(401, 'Session expired'); try { final data = await post('auth/refresh', {'refreshToken': refresh}, authenticated: false); await _saveSession(data); } catch (_) { await _session.clear(); rethrow; } }();
    _refreshing = future;
    try { await future; } finally { _refreshing = null; }
  }
  Future<void> _saveSession(Map<String, dynamic> data) => _session.save(data['accessToken'] as String, data['refreshToken'] as String);
  void close() => _client.close();
}
