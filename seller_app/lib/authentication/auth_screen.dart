import 'package:dierb_api_client/dierb_api_client.dart';
import 'package:flutter/material.dart';
import '../mainScreens/home_screen.dart';

class AuthScreen extends StatefulWidget { const AuthScreen({super.key}); @override State<AuthScreen> createState()=>_AuthScreenState(); }
class _AuthScreenState extends State<AuthScreen> {
  final api=DierbApi(), name=TextEditingController(), phone=TextEditingController(), email=TextEditingController(), password=TextEditingController(); bool register=false,loading=false; String? error;
  @override void dispose(){api.close();name.dispose();phone.dispose();email.dispose();password.dispose();super.dispose();}
  Future<void> _submit() async {
    if(!email.text.contains('@')||password.text.length<8||(register&&name.text.trim().length<2)){setState(()=>error='راجع البيانات، وكلمة المرور لازم تكون 8 حروف على الأقل.');return;}
    setState((){loading=true;error=null;});
    try{
      if(register){await api.register(email:email.text.trim(),password:password.text,name:name.text.trim(),phone:phone.text.trim(),role:'merchant');}else{await api.login(email.text.trim(),password.text,deviceName:'Dierb Merchant');}
      final profile=await api.profile(); if(profile['role']!='merchant'){await api.logout();throw const DierbApiException(403,'هذا الحساب ليس حساب تاجر');}
      if(mounted)Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const HomeScreen()),(_)=>false);
    }catch(e){if(mounted)setState(()=>error=e is DierbApiException?e.message:'تعذر تسجيل الدخول');}finally{if(mounted)setState(()=>loading=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(22),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:480),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    const CircleAvatar(radius:38,backgroundColor:Color(0xFFE0F2E9),child:Icon(Icons.storefront_rounded,size:42,color:Color(0xFF166534))),const SizedBox(height:16),const Text('ديرب للتجار',textAlign:TextAlign.center,style:TextStyle(fontSize:28,fontWeight:FontWeight.w900)),const SizedBox(height:6),Text(register?'أنشئ حساب تاجر وأرسل طلبك للإدارة':'ادخل لإدارة متجرك ومنتجاتك وطلباتك',textAlign:TextAlign.center),const SizedBox(height:26),
    if(register)...[TextField(controller:name,decoration:const InputDecoration(labelText:'اسم التاجر / النشاط',prefixIcon:Icon(Icons.store_outlined))),const SizedBox(height:10),TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'رقم الهاتف',prefixIcon:Icon(Icons.phone_outlined))),const SizedBox(height:10)],
    TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'البريد الإلكتروني',prefixIcon:Icon(Icons.email_outlined))),const SizedBox(height:10),TextField(controller:password,obscureText:true,onSubmitted:(_)=>_submit(),decoration:const InputDecoration(labelText:'كلمة المرور',prefixIcon:Icon(Icons.lock_outline))),
    if(error!=null)Padding(padding:const EdgeInsets.only(top:12),child:Text(error!,textAlign:TextAlign.center,style:TextStyle(color:Theme.of(context).colorScheme.error))),const SizedBox(height:18),FilledButton(onPressed:loading?null:_submit,child:Padding(padding:const EdgeInsets.symmetric(vertical:13),child:loading?const SizedBox.square(dimension:20,child:CircularProgressIndicator(strokeWidth:2)):Text(register?'إنشاء حساب التاجر':'تسجيل الدخول'))),TextButton(onPressed:loading?null:()=>setState((){register=!register;error=null;}),child:Text(register?'عندي حساب تاجر بالفعل':'إنشاء حساب تاجر جديد')),const Text('ظهور المتجر للعملاء يحتاج موافقة الإدارة.',textAlign:TextAlign.center,style:TextStyle(fontSize:12,color:Colors.black54)),
  ]))))));
}
