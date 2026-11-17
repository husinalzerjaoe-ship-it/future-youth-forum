import 'dart:math';
import 'package:flutter/material.dart';

class PenaltyShootoutPage extends StatefulWidget{
 const PenaltyShootoutPage({super.key});
 @override State<PenaltyShootoutPage> createState()=>_PenaltyShootoutPageState();
}
class _PenaltyShootoutPageState extends State<PenaltyShootoutPage>{
 final _rng=Random();int _shot=0,_goals=0,_saves=0;String _result='اختَر زاوية التسديد وابدأ التحدي!';
 bool _done=false;
 void _kick(String side){
  if(_done)return;
  final keeper=['يمين','وسط','يسار'][_rng.nextInt(3)];
  setState((){
   _shot++;
   if(side==keeper){_saves++;_result='الحارس تصدّى لها! 🧤';}
   else{_goals++;_result='گــــول! ⚽🔥';}
   if(_shot>=5){_done=true;_result='انتهت الركلات! نتيجتك $_goals من 5 • تصديات الحارس $_saves';}
  });
 }
 void _reset()=>setState((){_shot=0;_goals=0;_saves=0;_done=false;_result='اختَر زاوية التسديد وابدأ التحدي!';});
 @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
  appBar:AppBar(title:const Text('ضربات الجزاء')),
  body:ListView(padding:const EdgeInsets.all(18),children:[
   Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:Colors.green.shade800,borderRadius:BorderRadius.circular(20)),child:Column(children:[
    const Text('⚽ تحدي ركلات الترجيح',style:TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.bold)),
    const SizedBox(height:8),Text('الركلة $_shot / 5',style:const TextStyle(color:Colors.white)),
    Text('أهدافك: $_goals',style:const TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.bold)),
   ])),
   const SizedBox(height:18),
   Container(height:190,decoration:BoxDecoration(color:Colors.green.shade700,borderRadius:BorderRadius.circular(18),border:Border.all(color:Colors.white,width:3)),child:Stack(children:[
    const Align(alignment:Alignment.topCenter,child:Padding(padding:EdgeInsets.only(top:15),child:Text('🥅',style:TextStyle(fontSize:90)))),
    const Align(alignment:Alignment.bottomCenter,child:Padding(padding:EdgeInsets.only(bottom:20),child:Text('⚽',style:TextStyle(fontSize:34)))),
   ])),
   const SizedBox(height:16),Text(_result,textAlign:TextAlign.center,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
   const SizedBox(height:14),
   Row(children:[
    Expanded(child:FilledButton(onPressed:_done?null:()=>_kick('يمين'),child:const Text('يمين'))),
    const SizedBox(width:8),Expanded(child:FilledButton(onPressed:_done?null:()=>_kick('وسط'),child:const Text('وسط'))),
    const SizedBox(width:8),Expanded(child:FilledButton(onPressed:_done?null:()=>_kick('يسار'),child:const Text('يسار'))),
   ]),
   const SizedBox(height:10),OutlinedButton.icon(onPressed:_reset,icon:const Icon(Icons.replay),label:const Text('إعادة المباراة')),
  ]),
 ));
}
