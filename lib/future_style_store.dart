import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FutureStyleStorePage extends StatefulWidget {
  const FutureStyleStorePage({super.key});
  @override State<FutureStyleStorePage> createState() => _FutureStyleStorePageState();
}
class _StyleItem {
  final String id,name,category,description;
  final IconData icon;
  final int color,price;
  const _StyleItem(this.id,this.name,this.category,this.description,this.icon,this.color,this.price);
}
class _FutureStyleStorePageState extends State<FutureStyleStorePage> {
  static const _items=< _StyleItem>[
    _StyleItem('crown','تاج القائد','ألقاب','لقب ملكي ذهبي',Icons.workspace_premium,0xFFE3AF35,180),
    _StyleItem('star','نجم المجتمع','ألقاب','شارة نجم مضيئة',Icons.stars,0xFF4D9DDB,120),
    _StyleItem('creator','صانع الإبداع','ألقاب','للمبدعين وصناع المحتوى',Icons.draw,0xFF9A65D6,140),
    _StyleItem('friend','صديق الجميع','ألقاب','لقب اجتماعي لطيف',Icons.diversity_3,0xFF3EAA8A,100),
    _StyleItem('legend','أسطورة الملتقى','ألقاب','لقب مميز ونادر',Icons.military_tech,0xFFFFB52E,350),
    _StyleItem('explorer','مستكشف المستقبل','ألقاب','لعشاق الاكتشاف',Icons.explore,0xFF20A6A6,130),
    _StyleItem('thinker','العقل اللامع','ألقاب','لأصحاب الأفكار',Icons.psychology,0xFF6688E8,150),
    _StyleItem('artist','فنان الملتقى','ألقاب','لمحبي الفن والرسم',Icons.palette,0xFFE16A9B,130),
    _StyleItem('gamer','ملك الألعاب','ألقاب','لعشاق التحديات',Icons.sports_esports,0xFF9B70E8,160),
    _StyleItem('reader','صديق الكتب','ألقاب','لقراء المكتبة',Icons.menu_book,0xFFB78655,110),
    _StyleItem('goldframe','إطار ذهبي','إطارات','إطار ذهبي لصورة الحساب',Icons.crop_square,0xFFE0B34D,220),
    _StyleItem('blueframe','إطار سماوي','إطارات','إطار سماوي أنيق',Icons.crop_square,0xFF48A9D8,150),
    _StyleItem('purpleframe','إطار بنفسجي','إطارات','إطار بنفسجي متدرج',Icons.crop_square,0xFF9364D8,150),
    _StyleItem('roseframe','إطار وردي','إطارات','إطار وردي ناعم',Icons.crop_square,0xFFDB70A5,150),
    _StyleItem('mintframe','إطار زمردي','إطارات','إطار أخضر زمردي',Icons.crop_square,0xFF40B99A,150),
    _StyleItem('fireframe','إطار ناري','إطارات','إطار برتقالي حيوي',Icons.crop_square,0xFFE87543,190),
    _StyleItem('spark','لمعة النجوم','زخارف','زخرفة نجوم حول الهوية',Icons.auto_awesome,0xFFE5B94C,100),
    _StyleItem('flame','شعلة النشاط','زخارف','شارة شعلة للنشاط',Icons.local_fire_department,0xFFE87543,120),
    _StyleItem('leaf','ورقة هادئة','زخارف','زخرفة طبيعية',Icons.spa,0xFF52A879,90),
    _StyleItem('comet','مذنب المستقبل','زخارف','زخرفة فضائية',Icons.rocket_launch,0xFF6E81D9,130),
    _StyleItem('diamond','ماسة لامعة','زخارف','شارة ماسية',Icons.diamond,0xFF62C7E8,240),
    _StyleItem('moon','هلال الليل','زخارف','زخرفة ليلية',Icons.nightlight_round,0xFF7785D8,100),
    _StyleItem('oceanbubble','فقاعات المحيط','فقاعات','ستايل فقاعات أزرق',Icons.bubble_chart,0xFF299BC5,120),
    _StyleItem('violetbubble','فقاعات بنفسجية','فقاعات','ستايل محادثة بنفسجي',Icons.chat_bubble,0xFF9468D9,120),
    _StyleItem('goldbubble','فقاعات ذهبية','فقاعات','ستايل محادثة ذهبي',Icons.chat,0xFFD5A63B,180),
    _StyleItem('royalbadge','شارة ملكية','شارات','شارة صغيرة للملف',Icons.verified,0xFFE2B33C,200),
    _StyleItem('creativebadge','شارة مبدع','شارات','شارة للمبدعين',Icons.auto_awesome,0xFFAB6BD8,140),
    _StyleItem('friendlybadge','شارة اجتماعية','شارات','شارة صديق',Icons.favorite,0xFF48A989,100),
  ];
  final _db=FirebaseFirestore.instance;
  String _category='الكل';
  bool _busy=false;
  String get _uid=>FirebaseAuth.instance.currentUser!.uid;
  DocumentReference<Map<String,dynamic>> get _wallet=>_db.collection('coinWallets').doc(_uid);
  CollectionReference<Map<String,dynamic>> get _inventory=>_db.collection('users').doc(_uid).collection('styleInventory');
  DocumentReference<Map<String,dynamic>> get _profile=>_db.collection('publicProfiles').doc(_uid);
  List<String> get _categories=>['الكل',..._items.map((e)=>e.category).toSet()];
  bool get _isFounder => FirebaseAuth.instance.currentUser?.email?.toLowerCase()=='husinalzerjaoe@gmail.com';
  Future<void> _grantFounderCoins() async {
    if(!_isFounder||_busy)return;
    setState(()=>_busy=true);
    try{
      await _db.runTransaction((tx)async{
        final snap=await tx.get(_wallet);
        final old=(snap.data()?['coins'] as num?)?.toInt()??0;
        final values={'coins':old+500,'updatedAt':FieldValue.serverTimestamp(),'grantedBy':_uid};
        if(snap.exists)tx.update(_wallet,values);else tx.set(_wallet,values);
      });
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم إضافة 500 عملة إلى رصيد المؤسس')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر إضافة العملات: $e')));}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  Future<void> _equip(_StyleItem item) async {
    final data=<String,dynamic>{'customTitleUpdatedAt':FieldValue.serverTimestamp()};
    if(item.category=='ألقاب') {
      data.addAll({'customTitle':item.name,'customTitleColor':item.color,'customTitleEndColor':item.color,
        'customTitleFont':'default','customTitleGradient':false,'customTitleGlow':true,
        'customTitleIcon':item.id=='crown'?'👑':item.id=='legend'?'🏆':'⭐',
        'customTitleExpiresAt':null,'customTitleUpdatedAt':FieldValue.serverTimestamp()});
    } else if(item.category=='إطارات') {
      data.addAll({'profileFrameId':item.id,'profileFrameColor':item.color});
    } else {
      data.addAll({'profileDecoration':item.id,'profileDecorationColor':item.color});
    }
    await _profile.update(data);
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تم إظهار «${item.name}» في ملفك الشخصي')));
  }
  Future<void> _buy(_StyleItem item) async {
    if(_busy)return;
    setState(()=>_busy=true);
    try {
      final inventoryRef=_inventory.doc(item.id);
      var owned=false;
      await _db.runTransaction((tx) async {
        final walletSnap=await tx.get(_wallet);
        final itemSnap=await tx.get(inventoryRef);
        if(itemSnap.exists){owned=true;return;}
        if(!walletSnap.exists)throw StateError('رصيدك صفر حالياً. تحتاج عملات قبل الشراء.');
        final coins=(walletSnap.data()?['coins'] as num?)?.toInt()??0;
        if(coins<item.price)throw StateError('رصيدك غير كافٍ. تحتاج ${item.price} عملة.');
        tx.update(_wallet,{'coins':coins-item.price,'updatedAt':FieldValue.serverTimestamp()});
        tx.set(inventoryRef,{'itemId':item.id,'name':item.name,'category':item.category,'price':item.price,'purchasedAt':FieldValue.serverTimestamp()});
      });
      await _equip(item);
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(owned?'العنصر موجود عندك وتم تفعيله':'تم الشراء والتفعيل بنجاح')));
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ما تم الشراء: ${e.toString().replaceFirst('Bad state: ','')}')));
    }finally{if(mounted)setState(()=>_busy=false);}
  }
  @override Widget build(BuildContext context){
    final visible=_items.where((e)=>_category=='الكل'||e.category==_category).toList();
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(
      appBar:AppBar(title:const Text('متجر ستايل المستقبل')),
      body:Column(children:[
        StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(stream:_wallet.snapshots(),builder:(context,s){
          final coins=(s.data?.data()?['coins'] as num?)?.toInt()??0;
          return Container(margin:const EdgeInsets.fromLTRB(14,12,14,6),padding:const EdgeInsets.all(14),
            decoration:BoxDecoration(borderRadius:BorderRadius.circular(18),gradient:const LinearGradient(colors:[Color(0xFF28204F),Color(0xFF7053C8)])),
            child:Row(children:[const Icon(Icons.monetization_on_rounded,color:Color(0xFFFFD66B),size:32),const SizedBox(width:10),
              const Expanded(child:Text('رصيد العملات',style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold))),
              Text('$coins',style:const TextStyle(color:Colors.white,fontSize:23,fontWeight:FontWeight.w900)),
              if(_isFounder)IconButton(tooltip:'إضافة 500 عملة للمؤسس',onPressed:_busy?null:_grantFounderCoins,icon:const Icon(Icons.add_circle,color:Color(0xFFFFD66B))),
            ]));
        }),
        SizedBox(height:48,child:ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:10),
          children:_categories.map((c)=>Padding(padding:const EdgeInsets.symmetric(horizontal:4),
            child:ChoiceChip(label:Text(c),selected:_category==c,onSelected:(_)=>setState(()=>_category=c)))).toList())),
        Expanded(child:GridView.builder(padding:const EdgeInsets.all(12),itemCount:visible.length,
          gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,childAspectRatio:.82,crossAxisSpacing:10,mainAxisSpacing:10),
          itemBuilder:(context,index){
            final item=visible[index];
            return StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(stream:_inventory.doc(item.id).snapshots(),builder:(context,ownedSnap){
              final owned=ownedSnap.data?.exists==true;
              return Card(clipBehavior:Clip.antiAlias,child:Padding(padding:const EdgeInsets.all(11),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Expanded(child:Center(child:CircleAvatar(radius:34,backgroundColor:Color(item.color).withValues(alpha:.16),child:Icon(item.icon,color:Color(item.color),size:36)))),
                Text(item.name,style:const TextStyle(fontWeight:FontWeight.bold)),
                Text(item.description,maxLines:2,overflow:TextOverflow.ellipsis,style:Theme.of(context).textTheme.bodySmall),
                const SizedBox(height:4),
                Row(children:[const Icon(Icons.monetization_on,color:Color(0xFFD6A83B),size:17),const SizedBox(width:4),Text('${item.price} عملة',style:const TextStyle(fontWeight:FontWeight.bold))]),
                const SizedBox(height:5),
                SizedBox(width:double.infinity,child:FilledButton.tonal(onPressed:_busy?null:owned?()=>_equip(item):()=>_buy(item),child:Text(owned?'تفعيل العنصر':'شراء'))),
              ])));
            });
          })),
        Padding(padding:const EdgeInsets.fromLTRB(14,3,14,12),child:Text('العناصر التي تشتريها ترتبط بحسابك وتبقى في مخزونك عند تبديل الجهاز. تحتاج عملات يمنحها المؤسس؛ لا توجد مدفوعات حقيقية داخل التطبيق.',style:Theme.of(context).textTheme.bodySmall)),
      ]),
    ));
  }
}
