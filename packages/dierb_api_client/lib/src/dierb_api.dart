import'dart:convert';import'package:http/http.dart'as http;import'api_config.dart';import'api_exception.dart';import'session_store.dart';
class DierbApi{
 DierbApi({DierbApiConfig config=DierbApiConfig.fromEnvironment,http.Client?client,DierbSessionStore?session}):_config=config,_client=client??http.Client(),_session=session??DierbSessionStore();final DierbApiConfig _config;final http.Client _client;final DierbSessionStore _session;Future<void>?_refreshing;
 Future<Map<String,dynamic>>register({required String email,required String password,required String name,String role='customer'})async{final data=await post('auth/register',{'email':email,'password':password,'name':name,'role':role},authenticated:false);await _saveSession(data);return data;}
 Future<Map<String,dynamic>>login(String email,String password,{String?deviceName})async{final data=await post('auth/login',{'email':email,'password':password,'deviceName':deviceName},authenticated:false);await _saveSession(data);return data;}
 Future<void>logout()async{try{await post('auth/logout',{});}finally{await _session.clear();}}
 Future<List<dynamic>>categories()=>getList('catalog/categories',authenticated:false);
 Future<List<dynamic>>stores({String?cityId,String?categoryId})=>getList('catalog/stores',query:{if(cityId!=null)'cityId':cityId,if(categoryId!=null)'categoryId':categoryId},authenticated:false);
 Future<Map<String,dynamic>>createOrder(Map<String,dynamic>body)=>post('orders',body);
 Future<List<dynamic>>orders()=>getList('orders');
 Future<Map<String,dynamic>>transition(String id,String status)=>patch('orders/$id/status',{'status':status});
 Future<List<dynamic>>getList(String path,{Map<String,String>?query,bool authenticated=true})async{final value=await _request('GET',path,query:query,authenticated:authenticated);return value as List<dynamic>;}
 Future<Map<String,dynamic>>post(String path,Map<String,dynamic>body,{bool authenticated=true})async=>(await _request('POST',path,body:body,authenticated:authenticated))as Map<String,dynamic>;
 Future<Map<String,dynamic>>patch(String path,Map<String,dynamic>body)async=>(await _request('PATCH',path,body:body))as Map<String,dynamic>;
 Future<dynamic>_request(String method,String path,{Map<String,dynamic>?body,Map<String,String>?query,bool authenticated=true,bool retry=true})async{final token=authenticated?await _session.accessToken:null;final response=await _client.send(http.Request(method,_config.uri(path,query))..headers.addAll({'Accept':'application/json','Content-Type':'application/json',if(token!=null)'Authorization':'Bearer $token'})..body=body==null?'':jsonEncode(body)).timeout(_config.timeout);final text=await response.stream.bytesToString();if(response.statusCode==401&&authenticated&&retry){await _refresh();return _request(method,path,body:body,query:query,authenticated:authenticated,retry:false);}final decoded=text.isEmpty?null:jsonDecode(text);if(response.statusCode<200||response.statusCode>=300)throw DierbApiException(response.statusCode,decoded is Map?(decoded['message']?.toString()??'Server error'):'Server error',code:decoded is Map?decoded['code']?.toString():null);return decoded;}
 Future<void>_refresh()async{if(_refreshing!=null)return _refreshing;final future=()async{final refresh=await _session.refreshToken;if(refresh==null)throw const DierbApiException(401,'Session expired');try{final data=await post('auth/refresh',{'refreshToken':refresh},authenticated:false);await _saveSession(data);}catch(_){await _session.clear();rethrow;}}();_refreshing=future;try{await future;}finally{_refreshing=null;}}
 Future<void>_saveSession(Map<String,dynamic>d)=>_session.save(d['accessToken']as String,d['refreshToken']as String);
 void close()=>_client.close();
}
