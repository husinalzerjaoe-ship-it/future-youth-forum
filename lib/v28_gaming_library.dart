import 'package:flutter/material.dart';

class V28GamingLibraryPage extends StatefulWidget {
  const V28GamingLibraryPage({super.key});
  @override State<V28GamingLibraryPage> createState()=>_V28GamingLibraryPageState();
}
class _V28GamingLibraryPageState extends State<V28GamingLibraryPage> {
  String game='Mobile Legends', section='الكل', query='';
  static const mlbb=[
    ('تانك / مبادر','Tigreal • Atlas • Khufra','ابدأ بالتحمل وتقليل وقت الانتظار؛ افتح القتال بعد ظهور فريقك.','واجه المبادرة بالتطهير، التباعد، ومهارات إيقاف الاندفاع.','ضرر مستمر ضد الدروع + اختراق سحري/فيزيائي حسب مصدر الضرر.'),
    ('مقاتل / خط EXP','Terizla • Yu Zhong • Arlott','وازن بين التحمل والضرر؛ لا تدخل قبل معرفة مواقع الخصوم.','أوقف الاستدامة بالجرح العميق، وابتعد عن مهارات السحب.','جرح عميق ضد العلاج؛ درع/مقاومة حسب نوع ضرر الخصم.'),
    ('قاتل / غابة','Ling • Hayabusa • Nolan','راقب الخريطة، استهدف الخلفية، واحتفظ بمهارة الهروب.','حماية الخلفية، كشف الرؤية، التحكم الجماعي، والتجمع قرب الأهداف.','دفاع جسدي ضد الانفجار؛ تحكم وإبطاء لكسر الاندفاع.'),
    ('ساحر / وسط','Lylia • Valentina • Novaria','ادفع الموجة ثم تحرك؛ اختر اختراقاً أو دفاعاً حسب التهديد.','مقاومة سحرية، ضغط مبكر، وتفادي مهارات المنطقة.','اختراق سحري ضد المقاومة؛ درع سحري عند مواجهة انفجار سحري.'),
    ('رامي / ذهب','Brody • Claude • Beatrix','حافظ على المسافة، اجمع الذهب، ولا تصرف مهارة الهروب بلا داعٍ.','اغلق المسافة بحذر، وخصص حارساً لحماية الرامي.','درع جسدي ضد القتلة؛ جرح عميق ضد الشفاء.'),
    ('دعم / روامر','Mathilda • Diggie • Angela','راقب زملاءك وافتح الرؤية؛ توقيت الإنقاذ أهم من مطاردة القتل.','أولوية إسكات/تحكم الدعم، ثم فصل الحماية عن المهاجم.','اختيارات دفاعية ومضادة للشفاء وفق تشكيلة الخصم.'),
  ];
  static const emblems=[
    ('اغتيال','سرعة حركة + اختراق + موهبة انفجار','للأبطال الذين يعتمدون على دخول سريع وإنهاء هدف منفرد.'),
    ('ساحر','اختراق سحري + تقليل انتظار/استدامة + موهبة ضرر','للميد والسحرة؛ عدّلها ضد مقاومة السحر.'),
    ('رامي','سرعة هجوم/ضرر حرج + اختراق + موهبة قتال طويل','للرامي الذي يستفيد من الضربات المتكررة.'),
    ('مقاتل','هجوم تكيفي + استدامة + موهبة اشتباك','للقتال الممتد في خط EXP.'),
    ('دبابة','تحمل + دفاع مناسب + موهبة حماية','للروامر والمبادرين؛ بدّل الدفاع حسب ضرر الخصم.'),
    ('دعم','تقليل انتظار + حركة/شفاء + موهبة مساندة','للحماية والإنقاذ والتدوير.'),
  ];
  static const pubg=[
    ('إعدادات الحساسية','ابدأ بحساسية متوسطة، جرّب سحب الكاميرا والتتبع في ساحة التدريب، وعدّل تدريجياً لكل منظار. لا توجد قيمة واحدة تناسب كل هاتف.'),
    ('تخطيط الأزرار','ضع إطلاق النار والقفز والانحناء بمواقع لا تتعارض مع حركة الإبهام؛ جرّب تخطيط 3 أو 4 أصابع فقط إذا كان مريحاً.'),
    ('اختيار المعدات','للقتال القريب: سلاح سريع مع منظار قصير. للمدى المتوسط: ارتداد سهل التحكم ومنظار مناسب. احمل علاجاً وذخيرة متوازنة.'),
    ('الهبوط والتمركز','اختر نقطة هبوط تناسب خبرتك، اجمع تجهيزاً سريعاً، تحرك قبل تقلص المنطقة، واستفد من الغطاء بدل الركض المكشوف.'),
    ('الصوت والخريطة','استخدم مؤشرات الصوت والخريطة المصغرة لتقدير الاتجاه، ولا تكشف موقعك بلا حاجة.'),
    ('تحسين السلاسة','اخفض الظلال والمؤثرات أولاً إذا حدث تقطيع، واترك مساحة تخزين كافية وأغلق التطبيقات الثقيلة.'),
  ];
  @override Widget build(BuildContext context) {
    final isMl=game=='Mobile Legends';
    final List<List<String>> items=isMl
      ? mlbb.map((e)=>[e.$1,e.$2,e.$3,e.$4,e.$5]).toList()
      : pubg.map((e)=>[e.$1,e.$2]).toList();
    final filtered=items.where((e)=>query.isEmpty||e.join(' ').toLowerCase().contains(query.toLowerCase())).toList();
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(
      appBar:AppBar(title:const Text('مكتبة الألعاب الاحترافية')),
      body:ListView(padding:const EdgeInsets.all(14),children:[
        Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),gradient:const LinearGradient(colors:[Color(0xFF171936),Color(0xFF5B35B5),Color(0xFF087E91)])),child:const Text('دليل الأبطال والعدادات والتجهيزات\nأدلة عملية قابلة للتعديل حسب التحديثات وطريقة لعبك.',style:TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.w900))),
        const SizedBox(height:12),
        SegmentedButton<String>(segments:const [ButtonSegment(value:'Mobile Legends',label:Text('Mobile Legends'),icon:Icon(Icons.shield_moon)),ButtonSegment(value:'PUBG Mobile',label:Text('PUBG'),icon:Icon(Icons.sports_esports))],selected:{game},onSelectionChanged:(v)=>setState(()=>game=v.first)),
        const SizedBox(height:10),
        TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'ابحث عن بطل أو دور أو نصيحة'),onChanged:(v)=>setState(()=>query=v)),
        if(isMl) ...[
          Wrap(spacing:8,children:['الأبطال والعدادات','الإيمبلم','المعدات'].map((v)=>ChoiceChip(label:Text(v),selected:section==v,onSelected:(_)=>setState(()=>section=v))).toList()),
          if(section=='الإيمبلم'||section=='الكل') ...[
            const Text('مكتبة الإيمبلم',style:TextStyle(fontWeight:FontWeight.w900,fontSize:18)),
            ...emblems.map((e)=>Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.workspace_premium)),title:Text(e.$1),subtitle:Text(e.$2+'\n'+e.$3)))),
          ],
          if(section=='المعدات'||section=='الكل') const Card(child:Padding(padding:EdgeInsets.all(14),child:Text('عدادات المعدات: ضد العلاج اختر عنصر الجرح العميق المناسب لنوع الضرر؛ ضد الدروع زِد الاختراق؛ ضد الانفجار اشترِ دفاعاً جسدياً أو سحرياً حسب مصدر الضرر؛ ضد سرعة الهجوم استخدم عناصر تقليل سرعة الهجوم. لا تشتري بناءً ثابتاً—راقب تشكيلة الخصم أولاً.'))),
          if(section=='الأبطال والعدادات'||section=='الكل') ...[
            const Text('الأدوار والأبطال المضادون',style:TextStyle(fontWeight:FontWeight.w900,fontSize:18)),
            ...filtered.map((e)=>Card(child:Padding(padding:const EdgeInsets.all(13),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(e[0],style:const TextStyle(fontWeight:FontWeight.w900,fontSize:16)),Text('أمثلة: '+e[1]),Text('الخطة: '+e[2]),Text('العداد: '+e[3]),Text('المعدات: '+e[4])])))),
          ],
        ] else ...[
          const Text('دليل PUBG Mobile',style:TextStyle(fontWeight:FontWeight.w900,fontSize:18)),
          ...filtered.map((e)=>Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.tune)),title:Text(e[0]),subtitle:Text(e[1])))),
        ],
        const SizedBox(height:10),
        const Text('تنبيه: أسماء الأبطال والأمثلة إرشادية وليست ترتيب ميتا لحظياً. قد تتغير القوة والبناء بعد كل تحديث؛ قارنها برقعة اللعبة الحالية قبل اعتمادها.',style:TextStyle(color:Colors.grey,fontSize:12)),
      ]),
    ));
  }
}
