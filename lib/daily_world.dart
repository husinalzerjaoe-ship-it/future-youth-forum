import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyWorldPage extends StatefulWidget {
  const DailyWorldPage({super.key});
  @override State<DailyWorldPage> createState()=>_DailyWorldPageState();
}
class _DailyWorldPageState extends State<DailyWorldPage> with SingleTickerProviderStateMixin {
  late final tabs=TabController(length:4,vsync:this);
  DateTime? birthday;
  String mood='😊 مرتاح';
  final note=TextEditingController();
  bool done=false;
  @override void initState(){super.initState();_restoreLocalData();}
  @override void dispose(){tabs.dispose();note.dispose();super.dispose();}
  String get _todayKey {final d=DateTime.now();return '${d.year}-${d.month}-${d.day}';}
  Future<void> _restoreLocalData() async {
    final prefs=await SharedPreferences.getInstance();
    final savedBirthday=prefs.getString('daily_world_birthday');
    final savedDate=prefs.getString('daily_world_date');
    if(savedBirthday!=null) birthday=DateTime.tryParse(savedBirthday);
    if(savedDate==_todayKey){
      mood=prefs.getString('daily_world_mood')??mood;
      done=prefs.getBool('daily_world_done')??false;
      note.text=prefs.getString('daily_world_note')??'';
    }
    if(mounted)setState((){});
  }
  Future<void> _saveToday() async {
    final prefs=await SharedPreferences.getInstance();
    await prefs.setString('daily_world_date',_todayKey);
    await prefs.setString('daily_world_mood',mood);
    await prefs.setBool('daily_world_done',done);
    await prefs.setString('daily_world_note',note.text);
  }
  static const signs=[
    ['الجدي','♑','التراب','12/22','1/19','هادئ وعملي ويحب التخطيط.','خطوة ثابتة اليوم أفضل من استعجال النتيجة.'],
    ['الدلو','♒','الهواء','1/20','2/18','مستقل ويحب الأفكار الجديدة.','شارك فكرة لطيفة واستمع لرأي مختلف.'],
    ['الحوت','♓','الماء','2/19','3/20','خيالي وحساس ويقدّر التعاطف.','امنح نفسك وقتاً للراحة ولا تحمل كل شيء وحدك.'],
    ['الحمل','♈','النار','3/21','4/19','مبادر وشجاع ويحب الحركة.','ابدأ بالمهمة المؤجلة وقسّمها إلى خطوات.'],
    ['الثور','♉','التراب','4/20','5/20','صبور ويحب الاستقرار.','رتّب أمورك بهدوء واهتم بما يمنحك الطمأنينة.'],
    ['الجوزاء','♊','الهواء','5/21','6/20','فضولي واجتماعي.','تواصل مع شخص تحبه وتعلّم شيئاً جديداً.'],
    ['السرطان','♋','الماء','6/21','7/22','عاطفي ويهتم بأحبته.','اسأل عن شخص عزيز ولا تنسَ نفسك.'],
    ['الأسد','♌','النار','7/23','8/22','كريم وواثق ويحب الإبداع.','استخدم ثقتك لتشجيع شخص آخر.'],
    ['العذراء','♍','التراب','8/23','9/22','منظم ودقيق.','لا تطلب الكمال من نفسك؛ الإنجاز الجيد يكفي.'],
    ['الميزان','♎','الهواء','9/23','10/22','يبحث عن التوازن والعدل.','وازن بين وقتك واحتياجات الآخرين.'],
    ['العقرب','♏','الماء','10/23','11/21','عميق ومثابر.','اختر حواراً صريحاً بدلاً من كتمان ما يزعجك.'],
    ['القوس','♐','النار','11/22','12/21','متفائل ويحب الاستكشاف.','خطط لتجربة مفيدة أو قراءة موضوع جديد.'],
  ];
  static const tasks=['اقرأ عشر صفحات من كتاب تحبه.','أرسل رسالة امتنان لشخص وقف معك.','رتّب زاوية صغيرة من غرفتك.','تعلّم معلومة جديدة وشاركها.','ابتعد عن الهاتف نصف ساعة.','اكتب ثلاثة أشياء جميلة حدثت لك.','مارس المشي أو حركة خفيفة تناسبك.','ساعد شخصاً اليوم ولو بكلمة طيبة.','أنجز مهمة صغيرة كنت تؤجلها.','شارك اقتباساً إيجابياً في المجتمع.'];
  static const dua='اللَّهُمَّ إِنِّي أَسْتَخِيرُكَ بِعِلْمِكَ، وَأَسْتَقْدِرُكَ بِقُدْرَتِكَ، وَأَسْأَلُكَ مِنْ فَضْلِكَ الْعَظِيمِ، فَإِنَّكَ تَقْدِرُ وَلَا أَقْدِرُ، وَتَعْلَمُ وَلَا أَعْلَمُ، وَأَنْتَ عَلَّامُ الْغُيُوبِ. اللَّهُمَّ إِنْ كُنْتَ تَعْلَمُ أَنَّ هَذَا الْأَمْرَ خَيْرٌ لِي فِي دِينِي وَمَعَاشِي وَعَاقِبَةِ أَمْرِي، فَاقْدُرْهُ لِي وَيَسِّرْهُ لِي ثُمَّ بَارِكْ لِي فِيهِ، وَإِنْ كُنْتَ تَعْلَمُ أَنَّ هَذَا الْأَمْرَ شَرٌّ لِي فِي دِينِي وَمَعَاشِي وَعَاقِبَةِ أَمْرِي، فَاصْرِفْهُ عَنِّي وَاصْرِفْنِي عَنْهُ، وَاقْدُرْ لِيَ الْخَيْرَ حَيْثُ كَانَ ثُمَّ أَرْضِنِي بِهِ.';
  DateTime get now=>DateTime.now();
  int get taskIndex=>(now.year*372+now.month*31+now.day)%tasks.length;
  List<String>? get sign {
    if(birthday==null)return null;
    final m=birthday!.month,d=birthday!.day;
    for(final s in signs){
      final a=s[3].split('/').map(int.parse).toList(), b=s[4].split('/').map(int.parse).toList();
      final after=m>a[0]||(m==a[0]&&d>=a[1]), before=m<b[0]||(m==b[0]&&d<=b[1]);
      if(a[0]>b[0]?(after||before):(after&&before))return s;
    }
    return signs[0];
  }
  String get age {
    if(birthday==null)return '';
    var y=now.year-birthday!.year,m=now.month-birthday!.month,d=now.day-birthday!.day;
    if(d<0){d+=DateTime(now.year,now.month,0).day;m--;}
    if(m<0){m+=12;y--;}
    return y.toString()+' سنة و'+m.toString()+' شهر و'+d.toString()+' يوم';
  }
  int get daysLeft {
    if(birthday==null)return 0;
    var n=DateTime(now.year,birthday!.month,birthday!.day);
    if(!n.isAfter(DateTime(now.year,now.month,now.day)))n=DateTime(now.year+1,birthday!.month,birthday!.day);
    return n.difference(DateTime(now.year,now.month,now.day)).inDays;
  }
  Future<void> pick()async{
    final d=await showDatePicker(context:context,initialDate:birthday??DateTime(2000),firstDate:DateTime(1900),lastDate:now);
    if(d!=null){setState(()=>birthday=d);final prefs=await SharedPreferences.getInstance();await prefs.setString('daily_world_birthday',d.toIso8601String());}
  }
  Future<void> copy(String s)async{
    await Clipboard.setData(ClipboardData(text:s));
    if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم النسخ')));
  }
  @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
    appBar:AppBar(title:const Text('عالمك اليومي ✨'),bottom:TabBar(controller:tabs,isScrollable:true,tabs:const[
      Tab(icon:Icon(Icons.cake_outlined),text:'العمر والبرج'),Tab(icon:Icon(Icons.stars),text:'يوميات برجك'),Tab(icon:Icon(Icons.volunteer_activism),text:'الاستخارة'),Tab(icon:Icon(Icons.spa),text:'يومياتك')
    ])),
    body:TabBarView(controller:tabs,children:[ageTab(),horoscopeTab(),istikharaTab(),dailyTab()])
  ));
  Widget hero(String title,String sub,IconData icon)=>Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(gradient:LinearGradient(colors:[Theme.of(context).colorScheme.primary,Theme.of(context).colorScheme.tertiary]),borderRadius:BorderRadius.circular(20)),child:Row(children:[Icon(icon,color:Colors.white,size:40),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:21)),Text(sub,style:const TextStyle(color:Colors.white,height:1.5))]))]));
  Widget ageTab()=>ListView(padding:const EdgeInsets.all(16),children:[
    hero('احسب عمرك وتعرّف على برجك','معلومات خفيفة للتسلية والتعرّف على الذات.',Icons.auto_awesome),
    const SizedBox(height:12),Card(child:ListTile(leading:const Icon(Icons.calendar_month),title:Text(birthday==null?'اختَر تاريخ ميلادك':birthday!.day.toString()+'/'+birthday!.month.toString()+'/'+birthday!.year.toString()),trailing:FilledButton(onPressed:pick,child:const Text('اختيار')))),
    if(birthday!=null)Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(children:[
      const Text('عمرك الحالي'),Text(age,style:TextStyle(fontSize:23,fontWeight:FontWeight.bold,color:Theme.of(context).colorScheme.primary)),
      Text(daysLeft==0?'عيد ميلادك اليوم 🎂':'باقي '+daysLeft.toString()+' يوم على عيد ميلادك'),
      const SizedBox(height:12),Text(sign![1],style:const TextStyle(fontSize:52)),Text('برج '+sign![0],style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),Text('العنصر: '+sign![2]),Text(sign![5],textAlign:TextAlign.center),
      const Text('الأبراج للتسلية فقط وليست وصفاً علمياً للشخصية.',style:TextStyle(color:Colors.grey))
    ]))),
    const Text('تاريخ الميلاد يُستخدم داخل هذه الشاشة فقط ولا يُرسل إلى الخادم.',style:TextStyle(color:Colors.grey))
  ]);
  Widget horoscopeTab()=>ListView(padding:const EdgeInsets.all(16),children:[
    hero('رسالة برجك اليومية','تأملات تشجيعية حسب برجك، وليست تنبؤاً بالمستقبل.',Icons.stars),
    const SizedBox(height:12),
    if(sign==null)const Card(child:ListTile(leading:Icon(Icons.cake),title:Text('حدد تاريخ ميلادك من تبويب العمر والبرج أولاً.'))),
    if(sign!=null)Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(children:[
      Text(sign![1],style:const TextStyle(fontSize:58)),Text('برج '+sign![0],style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
      const SizedBox(height:16),Text(sign![6],style:const TextStyle(fontSize:19,height:1.8),textAlign:TextAlign.center),
      Text('رسالة اليوم: '+now.day.toString()+'/'+now.month.toString()+'/'+now.year.toString(),style:const TextStyle(color:Colors.grey)),
      OutlinedButton.icon(onPressed:()=>copy('برج '+sign![0]+': '+sign![6]+'\nللتسلية والتأمل فقط.'),icon:const Icon(Icons.copy),label:const Text('نسخ الرسالة'))
    ]))),
    const Card(child:Padding(padding:EdgeInsets.all(16),child:Text('الأبراج لا تكشف الغيب ولا تحدد الحظ أو القرارات. اعتبر الرسالة عبارة إيجابية فقط.',style:TextStyle(height:1.7))))
  ]);
  Widget istikharaTab()=>ListView(padding:const EdgeInsets.all(16),children:[
    hero('دليل صلاة الاستخارة','طلب الخير من الله عند التردد في أمر مباح.',Icons.volunteer_activism),
    const Card(child:Padding(padding:EdgeInsets.all(16),child:Text('الخطوات:\n١. توضأ وصلِّ ركعتين من غير الفريضة.\n٢. بعد الصلاة ادعُ بدعاء الاستخارة.\n٣. عند قول «هذا الأمر» سمِّ حاجتك أو استحضرها بقلبك.\n٤. خذ بالأسباب واستشر أهل الخبرة وتوكّل على الله. لا يشترط أن ترى حلماً أو علامة.',style:TextStyle(height:1.9)))),
    Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('دعاء الاستخارة',style:TextStyle(fontWeight:FontWeight.bold,fontSize:20)),const SizedBox(height:12),
      SelectableText(dua,style:const TextStyle(fontSize:18,height:2)),
      Align(alignment:Alignment.centerLeft,child:IconButton(onPressed:()=>copy(dua),icon:const Icon(Icons.copy)))
    ]))),
    const Card(child:Padding(padding:EdgeInsets.all(16),child:Text('هذا دليل عام وليس فتوى لحالة خاصة. للأسئلة الفقهية التفصيلية راجع عالماً موثوقاً.',style:TextStyle(height:1.7))))
  ]);
  Widget dailyTab()=>ListView(padding:const EdgeInsets.all(16),children:[
    hero('مساحتك اليومية','تابع مزاجك وخذ خطوة صغيرة لنفسك.',Icons.spa),
    Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('شلون مزاجك اليوم؟',style:TextStyle(fontWeight:FontWeight.bold,fontSize:18)),
      Wrap(spacing:7,children:['😊 مرتاح','😐 عادي','😔 متضايق','🤩 متحمس','😴 تعبان'].map((m)=>ChoiceChip(label:Text(m),selected:mood==m,onSelected:(_){setState(()=>mood=m);_saveToday();})).toList()),
      Text('اختيارك: '+mood)
    ]))),
    Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('تحدي اليوم',style:TextStyle(fontWeight:FontWeight.bold,fontSize:19)),const SizedBox(height:8),
      Text(tasks[taskIndex],style:const TextStyle(fontSize:18,height:1.6)),
      CheckboxListTile(value:done,onChanged:(v){setState(()=>done=v??false);_saveToday();},title:const Text('أنجزت تحدي اليوم'),contentPadding:EdgeInsets.zero)
    ]))),
    Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('فضفضة قصيرة',style:TextStyle(fontWeight:FontWeight.bold,fontSize:18)),
      TextField(controller:note,maxLines:4,maxLength:500,decoration:const InputDecoration(hintText:'اكتب فكرة أو شيئاً ممتناً له اليوم...',border:OutlineInputBorder())),
      const Text('تُحفظ يومياتك ومزاجك وتحدي اليوم على هذا الجهاز فقط.',style:TextStyle(color:Colors.grey,fontSize:12)),
      Wrap(alignment:WrapAlignment.end,spacing:8,children:[
        FilledButton.icon(onPressed:()async{await _saveToday();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حفظ يومياتك على الجهاز')));},icon:const Icon(Icons.save_outlined),label:const Text('حفظ اليوميات')),
        TextButton.icon(onPressed:()=>copy(note.text),icon:const Icon(Icons.copy),label:const Text('نسخ ملاحظتي'))
      ])
    ])))
  ]);
}
