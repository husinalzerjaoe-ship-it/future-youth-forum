import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegionChatHubPage extends StatelessWidget {
  const RegionChatHubPage({super.key});

  static const _regions = <({String id, String name, String subtitle, String flag, IconData icon})>[
    (id:'iraq',name:'العراق',subtitle:'مجلس العراق العام',flag:'🇮🇶',icon:Icons.location_city_rounded),
    (id:'baghdad',name:'بغداد',subtitle:'أهل العاصمة وأصدقاؤها',flag:'🏙️',icon:Icons.apartment_rounded),
    (id:'basra',name:'البصرة',subtitle:'مجلس الفيحاء',flag:'🌴',icon:Icons.water_rounded),
    (id:'mosul',name:'الموصل',subtitle:'مجلس نينوى',flag:'🏛️',icon:Icons.account_balance_rounded),
    (id:'erbil',name:'أربيل',subtitle:'مجلس كردستان',flag:'⛰️',icon:Icons.landscape_rounded),
    (id:'syria',name:'سوريا',subtitle:'مجلس سوريا العام',flag:'🇸🇾',icon:Icons.diversity_3_rounded),
    (id:'damascus',name:'دمشق',subtitle:'مجلس الشام',flag:'🌿',icon:Icons.park_rounded),
    (id:'aleppo',name:'حلب',subtitle:'مجلس حلب وأهلها',flag:'🏘️',icon:Icons.home_work_rounded),
    (id:'gulf',name:'الخليج',subtitle:'مجلس أهل الخليج',flag:'🌊',icon:Icons.waves_rounded),
    (id:'levant',name:'بلاد الشام',subtitle:'مجلس بلاد الشام',flag:'🌸',icon:Icons.public_rounded),
  ];

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('مجالس البلدان والمدن')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(colors:[Color(0xFF25245C),Color(0xFF6554D9)]),
            ),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
              Text('مجالس تجمعنا',style:TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.bold)),
              SizedBox(height:6),
              Text('اختار بلدك أو مدينتك وتبادل الحديث مع الأعضاء باحترام.',style:TextStyle(color:Colors.white70,height:1.5)),
            ]),
          ),
          const SizedBox(height:12),
          ..._regions.map((r)=>Card(
            child: ListTile(
              contentPadding:const EdgeInsets.symmetric(horizontal:14,vertical:7),
              leading:CircleAvatar(radius:25,child:Text(r.flag,style:const TextStyle(fontSize:22))),
              title:Text(r.name,style:const TextStyle(fontWeight:FontWeight.bold)),
              subtitle:Text(r.subtitle),
              trailing:const Icon(Icons.chevron_left_rounded),
              onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>RegionalChatRoomPage(roomId:r.id,title:r.name,flag:r.flag))),
            ),
          )),
          const Padding(
            padding:EdgeInsets.all(8),
            child:Text('المجالس تستخدم رسائل نصية مباشرة. لا نعرض عدداً وهمياً للحاضرين؛ ميزات الحضور والوسائط تُضاف بعد ربطها واختبارها.',style:TextStyle(fontSize:11,color:Colors.grey)),
          ),
        ],
      ),
    ),
  );
}

class RegionalChatRoomPage extends StatefulWidget {
  const RegionalChatRoomPage({super.key,required this.roomId,required this.title,required this.flag});
  final String roomId,title,flag;
  @override State<RegionalChatRoomPage> createState()=>_RegionalChatRoomPageState();
}

class _RegionalChatRoomPageState extends State<RegionalChatRoomPage> {
  final _text=TextEditingController();
  final _scroll=ScrollController();
  bool _sending=false;
  String? _error;
  String get _uid=>FirebaseAuth.instance.currentUser!.uid;
  CollectionReference<Map<String,dynamic>> get _messages=>FirebaseFirestore.instance.collection('regionalChats').doc(widget.roomId).collection('messages');

  @override void dispose(){_text.dispose();_scroll.dispose();super.dispose();}

  Future<void> _send({String? sticker}) async {
    final user=FirebaseAuth.instance.currentUser;
    if(user==null||_sending)return;
    final value=(sticker??_text.text).trim();
    if(value.isEmpty||value.length>1000)return;
    setState(()=>_sending=true);
    try{
      final profile=await FirebaseFirestore.instance.collection('publicProfiles').doc(_uid).get();
      final data=profile.data()??{};
      final name=(data['name']??user.displayName??'عضو').toString();
      final photo=(data['photoUrl']??'').toString();
      await _messages.add({
        'senderId':_uid,
        'senderName':name,
        'senderPhoto':photo,
        'senderRole':user.email?.toLowerCase()=='husinalzerjaoe@gmail.com'?'founder':'member',
        'type':sticker==null?'text':'sticker',
        'text':value,
        'createdAt':FieldValue.serverTimestamp(),
      });
      if(sticker==null)_text.clear();
      if(mounted)setState(()=>_error=null);
    }catch(e){
      if(mounted)setState(()=>_error='تعذر إرسال الرسالة. تحقق من الاتصال وصلاحيات الغرفة.');
    }finally{if(mounted)setState(()=>_sending=false);}
  }

  @override
  Widget build(BuildContext context){
    final user=FirebaseAuth.instance.currentUser;
    if(user==null)return const Scaffold(body:Center(child:Text('سجّل الدخول أولاً.')));
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(
      appBar:AppBar(title:Text('${widget.flag} مجلس ${widget.title}')),
      body:Column(children:[
        Container(
          width:double.infinity,padding:const EdgeInsets.symmetric(horizontal:14,vertical:9),
          color:Theme.of(context).colorScheme.surfaceContainer,
          child:const Text('احترم الآخرين، ولا تشارك معلوماتك الخاصة.',style:TextStyle(fontSize:12)),
        ),
        Expanded(child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
          stream:_messages.orderBy('createdAt',descending:true).limit(100).snapshots(),
          builder:(context,snapshot){
            if(snapshot.hasError)return const Center(child:Text('تعذر تحميل رسائل هذا المجلس. قد تحتاج صلاحيات قاعدة البيانات إلى مراجعة.'));
            if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());
            final docs=snapshot.data!.docs;
            if(docs.isEmpty)return const Center(child:Text('بداية المجلس هنا! اكتب أول رسالة 👋'));
            return ListView.builder(
              reverse:true,padding:const EdgeInsets.all(12),itemCount:docs.length,
              itemBuilder:(context,index){
                final d=docs[index].data();
                final mine=d['senderId']==_uid;
                final body=(d['text']??'').toString();
                final name=(d['senderName']??'عضو').toString();
                final photo=(d['senderPhoto']??'').toString();
                final role=d['senderRole']=='founder';
                return Align(
                  alignment:mine?Alignment.centerLeft:Alignment.centerRight,
                  child:Container(
                    constraints:BoxConstraints(maxWidth:MediaQuery.of(context).size.width*.82),
                    margin:const EdgeInsets.only(bottom:9),
                    padding:const EdgeInsets.all(11),
                    decoration:BoxDecoration(
                      color:mine?Theme.of(context).colorScheme.primaryContainer:Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius:BorderRadius.circular(16),
                    ),
                    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                      Row(mainAxisSize:MainAxisSize.min,children:[
                        CircleAvatar(radius:12,backgroundImage:photo.startsWith('https://')?NetworkImage(photo):null,child:!photo.startsWith('https://')?const Icon(Icons.person,size:14):null),
                        const SizedBox(width:6),
                        Flexible(child:Text(name,style:TextStyle(fontWeight:FontWeight.bold,color:role?const Color(0xFFB8860B):null))),
                        if(role)const Padding(padding:EdgeInsets.only(right:4),child:Icon(Icons.verified,size:14,color:Color(0xFFB8860B))),
                      ]),
                      const SizedBox(height:5),
                      SelectableText(body,style:TextStyle(fontSize:body.length<=4?24:15)),
                    ]),
                  ),
                );
              },
            );
          },
        )),
        if(_error!=null)Padding(padding:const EdgeInsets.symmetric(horizontal:12),child:Text(_error!,style:const TextStyle(color:Colors.red,fontSize:12))),
        SizedBox(height:43,child:ListView(
          scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:8),
          children:['😀','😂','❤️','🔥','👏','🌹','🇮🇶','🇸🇾','⚽','🎉','✨'].map((e)=>IconButton(onPressed:_sending?null:()=>_send(sticker:e),icon:Text(e,style:const TextStyle(fontSize:22)))).toList(),
        )),
        SafeArea(top:false,child:Padding(
          padding:const EdgeInsets.fromLTRB(10,4,10,10),
          child:Row(children:[
            Expanded(child:TextField(controller:_text,maxLines:4,minLines:1,maxLength:1000,textInputAction:TextInputAction.send,onSubmitted:(_)=>_send(),decoration:InputDecoration(counterText:'',hintText:'اكتب رسالتك...',border:OutlineInputBorder(borderRadius:BorderRadius.circular(22))))),
            const SizedBox(width:8),
            IconButton.filled(onPressed:_sending?null:()=>_send(),icon:_sending?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.send_rounded)),
          ]),
        )),
      ]),
    ));
  }
}
