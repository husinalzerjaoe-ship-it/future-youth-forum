import 'dart:math';
import 'package:flutter/material.dart';

class ArcadeMiniGamesPage extends StatefulWidget {
 const ArcadeMiniGamesPage({super.key});
 @override State<ArcadeMiniGamesPage> createState()=>_ArcadeMiniGamesPageState();
}
class _ArcadeMiniGamesPageState extends State<ArcadeMiniGamesPage>{
 final _rng=Random();
 final _symbols=['⚽','🎮','🚀','⭐','🎧','🐉','🏆','🔥'];
 late List<String> _cards;
 final Set<int> _open={};
 final Set<int> _matched={};
 int _moves=0;
 int _number=0;
 String _scrambled='';
 String _word='';
 final _words=['ملعب','بطولة','مهاجم','حارس','جمهور','مهارة','تحدي','فريق'];
 @override void initState(){super.initState();_resetMemory();_newWord();}
 void _resetMemory(){_cards=[..._symbols,..._symbols]..shuffle(_rng);_open.clear();_matched.clear();_moves=0;}
 void _newWord(){_word=_words[_rng.nextInt(_words.length)];_scrambled=String.fromCharCodes(_word.runes.toList()..shuffle(_rng));}
 void _tapCard(int i){
  if(_matched.contains(i)||_open.contains(i)||_open.length>=2)return;
  setState(()=>_open.add(i));
  if(_open.length==2){
   final pair=_open.toList();
   if(_cards[pair[0]]==_cards[pair[1]]){
    setState((){_matched.addAll(pair);_open.clear();_moves++;});
   }else{
    Future.delayed(const Duration(milliseconds:750),(){if(mounted)setState((){_open.clear();_moves++;});});
   }
  }
 }
 @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
  appBar:AppBar(title:const Text('ألعاب الذكاء والتحدي')),
  body:ListView(padding:const EdgeInsets.all(16),children:[
   Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    const Text('🧠 ذاكرة الرموز',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
    Text('طابق كل زوج بأقل عدد من الحركات • الحركات: $_moves • الأزواج: ${_matched.length~/2}/8'),
    const SizedBox(height:10),
    GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:16,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:4,crossAxisSpacing:7,mainAxisSpacing:7),itemBuilder:(context,i)=>InkWell(
     onTap:()=>_tapCard(i),child:Container(decoration:BoxDecoration(color:_matched.contains(i)?Colors.green.withOpacity(.18):Theme.of(context).colorScheme.surfaceContainerHighest,borderRadius:BorderRadius.circular(12)),child:Center(child:Text(_matched.contains(i)||_open.contains(i)?_cards[i]:'❔',style:const TextStyle(fontSize:26)))),
    )),
    TextButton(onPressed:()=>setState(_resetMemory),child:const Text('إعادة لعبة الذاكرة')),
   ]))),
   Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    const Text('🔤 فك الكلمة',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
    const Text('رتّب الحروف حتى تكتشف كلمة من عالم الرياضة'),
    const SizedBox(height:8),Center(child:Text(_scrambled,style:const TextStyle(fontSize:28,fontWeight:FontWeight.bold,letterSpacing:5))),
    TextField(onChanged:(v)=>_wordGuess=v,decoration:const InputDecoration(labelText:'اكتب الكلمة الصحيحة')),
    FilledButton(onPressed:(){if(_wordGuess.trim()==_word){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('أحسنت! إجابة صحيحة 🎉')));setState((){_newWord();_wordGuess='';});}else{ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('مو صحيح، حاول مرة ثانية')));}},child:const Text('تحقق')),
    TextButton(onPressed:()=>setState(_newWord),child:const Text('كلمة جديدة')),
   ]))),
   Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    const Text('🔢 خمن الرقم',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
    const Text('أنا مختار رقم من 1 إلى 20. حاول تخمنه!'),
    TextField(key:ValueKey(_number),keyboardType:TextInputType.number,onChanged:(v)=>_numberGuess=int.tryParse(v)??0,decoration:const InputDecoration(labelText:'تخمينك')),
    FilledButton(onPressed:(){final n=_rng.nextInt(20)+1;if(_numberGuess==n){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('رائع! خمنت الرقم الصحيح')));}else{ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('كان الرقم $n — جرب مرة ثانية')));}setState(()=>_number++);},child:const Text('اكشف الرقم')),
   ]))),
  ]),
 ));
 String _wordGuess='';
 int _numberGuess=0;
}
