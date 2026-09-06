import 'package:dierb_api_client/dierb_api_client.dart';
import 'package:flutter/material.dart';

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({super.key});
  @override State<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends State<NotificationCenterPage> {
  final api = DierbApi(); List<dynamic>? items; String? error;
  @override void initState(){super.initState();load();}
  @override void dispose(){api.close();super.dispose();}
  Future<void> load() async { try { final value=await api.notifications(); if(mounted)setState((){items=value;error=null;}); } catch(e){if(mounted)setState(()=>error=e is DierbApiException?e.message:'تعذر تحميل الإشعارات');} }
  Future<void> read(Map<String,dynamic> n) async {if(n['readAt']==null){await api.markNotificationRead(n['id'].toString());await load();}}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('الإشعارات'),actions:[TextButton(onPressed:items?.any((x)=>(x as Map)['readAt']==null)==true?()async{await api.markAllNotificationsRead();await load();}:null,child:const Text('قراءة الكل'))]),body:error!=null?Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Text(error!),TextButton(onPressed:load,child:const Text('حاول تاني'))])):items==null?const Center(child:CircularProgressIndicator()):items!.isEmpty?const Center(child:Text('لا توجد إشعارات جديدة')):RefreshIndicator(onRefresh:load,child:ListView.separated(padding:const EdgeInsets.all(16),itemCount:items!.length,separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(_,i){final n=Map<String,dynamic>.from(items![i]as Map),unread=n['readAt']==null;return Card(color:unread?const Color(0xFFEAF4F0):null,child:ListTile(onTap:()=>read(n),leading:Icon(unread?Icons.notifications_active_rounded:Icons.notifications_none_rounded,color:const Color(0xFF166534)),title:Text((n['title']??'إشعار من ديرب').toString(),style:TextStyle(fontWeight:unread?FontWeight.w900:FontWeight.w700)),subtitle:Text((n['body']??'').toString()),trailing:unread?const CircleAvatar(radius:5,backgroundColor:Color(0xFF166534)):null));})));
}
