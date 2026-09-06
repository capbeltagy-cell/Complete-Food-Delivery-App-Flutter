import 'package:dierb_api_client/dierb_api_client.dart';
import 'package:flutter/material.dart';
import '../authentication/auth_screen.dart';
import '../mainScreens/home_screen.dart';

class MySplashScreen extends StatefulWidget { const MySplashScreen({super.key}); @override State<MySplashScreen> createState()=>_MySplashScreenState(); }
class _MySplashScreenState extends State<MySplashScreen>{
  final api=DierbApi();
  @override void initState(){super.initState();_route();}
  Future<void> _route()async{final signed=await api.hasSession;api.close();if(!mounted)return;Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>signed?const HomeScreen():const AuthScreen()));}
  @override Widget build(BuildContext context)=>const Scaffold(body:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[CircleAvatar(radius:48,backgroundColor:Color(0xFFE0F2E9),child:Icon(Icons.storefront_rounded,size:54,color:Color(0xFF166534))),SizedBox(height:18),Text('ديرب للتجار',style:TextStyle(fontSize:30,fontWeight:FontWeight.w900)),SizedBox(height:6),Text('متجرك وطلباتك في مكان واحد')] )));
}
