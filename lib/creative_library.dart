import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:url_launcher/url_launcher.dart';

class CreativeLibraryPage extends StatefulWidget {
  const CreativeLibraryPage({super.key});
  @override State<CreativeLibraryPage> createState()=>_CreativeLibraryPageState();
}

class _CreativeLibraryPageState extends State<CreativeLibraryPage> {
  final search=TextEditingController();
  String category='الكل';
  static const categories=[
    'الكل','شعر فصيح','شعر شعبي','اقتباسات','حكم','أدعية','أذكار','آيات قرآنية',
    'تهاني ومعايدات','خذلان وفراق','نكت عراقية','نكت خليجية'
  ];
  static const Map<String,List<String>> library={
    'شعر فصيح':[
      'إذا ضاقَ دربُ المرءِ فالصبرُ مركبٌ\nومن بعدِ ليلِ الحزنِ فجرٌ يُبشّرُ',
      'نمضي وتبقى في المواقفِ سيرةٌ\nفالطيبُ أثرٌ لا يزولُ ويُنسى',
      'يا صاحِ لا تيأسْ إذا طالَ المدى\nفالفجرُ يولدُ من عيونِ الساهرِ',
      'للعلمِ أبوابٌ تضيءُ طريقَنا\nوبنورِهِ تسمو العقولُ وتكبرُ',
      'أمي دعاءٌ في الفؤادِ أُردّدُهُ\nوبظلِّ حبِّكِ يستريحُ خاطري',
      'وطني وإن بعدتْ خطايَ أحبُّهُ\nفترابُهُ في مهجتي لا يُغتفرُ',
      'لا تحسبنَّ المجدَ يأتي راحةً\nفالسعيُ يرفعُ من أرادَ المعالي',
      'إذا زرعتَ الخيرَ في دربِ الورى\nأزهرتْ قلوبٌ لا تراها عينُك',
      'وفي الصداقةِ صادقٌ متبسّمٌ\nيمحو العناءَ إذا الزمانُ تجبّرا',
      'للروحِ نافذةٌ اسمُها أملٌ\nمنها يطلُّ النورُ مهما أظلما',
      'وما قيمةُ الإنسانِ إلا فعلُهُ\nفالذكرُ يبقى والوجوهُ تغيبُ',
      'سلامٌ على قلبٍ إذا اشتدَّ الأسى\nرأى في رجاءِ اللهِ باباً أوسعا'
    ],
    'شعر شعبي':[
      'يا صاحبي لا تنحني لو جار بيك الوقت\nباجر يجي فرحٍ يبدّل كل هالضيجة',
      'يمّه دعائج بالضلوع وما يفارقني\nومن أسمع اسمج يبتسم كلبي التعبان',
      'بغداد يا ضحكة شوارعنه القديمة\nحبج بگلبي لو يطول العمر ما يبرد',
      'لا تبيع الطيب لو دنياك صارت قاسية\nالطيب يبقى والردي تكشفه الأيام',
      'يا ليل خلّي نجمةٍ تدلّني دربي\nتعبت أدور للفرح عنوان بغيابك',
      'مو كلمن يضحك تراه بخير ومرتاح\nبعض الوجيه تخبّي ألف حچاية',
      'العشرة مو حچي ومواعيد ووعود\nالعشرة مواقف من تضيج الدنيا بيك',
      'أحبك كثر ما مرّ طيفك في خيالي\nوكثر المطر لا هبّت بوجه الصحاري',
      'يا ديرة العزّة تره حبج سكن بالروح\nوكل الدروب البعيدة تردّني يمّج',
      'خلّ الأمل بعيونك يضوي مثل نجمة ليل\nما دام ربك موجود لا تيأس من الفرج',
      'الما يصون الود لا تعاتبه هواي\nخلّيه يتعلّم من غيابك شگد غالي',
      'من طيب أصلك ينزرع للناس ألف إحساس\nوالناس تعرف معدن الطيب بالمواقف'
    ],
    'اقتباسات':[
      'لا تجعل يومك نسخةً من خوف الأمس.',
      'بعض الطرق تتأخر، لكنها تعلّمنا كيف نصل.',
      'الكلمة الطيبة لا تحتاج إلى مناسبة.',
      'ليس كل صمتٍ ضعفاً؛ أحياناً هو احترامٌ للنفس.',
      'الأثر الجميل أطول عمراً من لحظة الحضور.',
      'لا تقِس قيمتك بمقدار انتباه الآخرين إليك.',
      'حين تعرف وجهتك، تصبح الخطوات الصغيرة إنجازاً.',
      'امنح قلبك فرصةً للراحة كما تمنح عقلك فرصةً للتفكير.',
      'الصدق لا يرفع الصوت؛ تكفيه الحقيقة.',
      'لا تؤجل الامتنان حتى تفقد ما تحب.',
      'أجمل الانتصارات أن تبقى إنساناً رغم القسوة.',
      'من عرف قدر وقته، عرف قدر حياته.'
    ],
    'حكم':[
      'من أصلح سريرته أصلح الله علانيته.',
      'التأنّي لا يمنع الوصول، بل يمنع كثيراً من الندم.',
      'من راقب كلامه قلّت عثراته.',
      'العلم سؤالٌ صادق قبل أن يكون جواباً.',
      'لا تحكم على كتابٍ من غلافه ولا على إنسانٍ من لحظة.',
      'الاعتذار شجاعة، وتكرار الخطأ اختيار.',
      'من حفظ الودّ وقت الخلاف عرف معنى الوفاء.',
      'ليس الغنى بكثرة ما تملك، بل بقلة ما تحتاج.',
      'الوقت الذي تمنحه للتعلّم لا يضيع.',
      'اختر معاركك؛ فليس كل خلاف يستحق قلبك.',
      'من زرع المعروف حصد المحبة.',
      'النجاح عادةٌ صغيرة تتكرر بإخلاص.'
    ],
    'أدعية':[
      'اللهم اشرح صدري ويسّر أمري واهدِ قلبي.',
      'اللهم ارزقني رزقاً طيباً واسعاً مباركاً فيه.',
      'اللهم اغفر لي ولوالديّ وارحمهما كما ربياني صغيراً.',
      'اللهم اجعل القادم من أيامي خيراً مما مضى.',
      'اللهم إني أسألك العفو والعافية في الدنيا والآخرة.',
      'ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة وقنا عذاب النار.',
      'اللهم أصلح لي ديني ودنياي وأهلي ومالي.',
      'اللهم اجعل لي من كل همّ فرجاً ومن كل ضيق مخرجاً.',
      'يا مقلب القلوب ثبت قلبي على دينك.',
      'اللهم احفظ أهلنا وأحبتنا وبلادنا من كل سوء.'
    ],
    'أذكار':[
      'سبحان الله وبحمده، سبحان الله العظيم.',
      'أستغفر الله وأتوب إليه.',
      'لا حول ولا قوة إلا بالله.',
      'حسبي الله لا إله إلا هو عليه توكلت وهو رب العرش العظيم.',
      'اللهم صلِّ وسلم على نبينا محمد.',
      'رضيت بالله رباً، وبالإسلام ديناً، وبمحمدٍ نبياً.',
      'بسم الله الذي لا يضر مع اسمه شيء في الأرض ولا في السماء وهو السميع العليم.',
      'أعوذ بكلمات الله التامات من شر ما خلق.',
      'سبحان الله، والحمد لله، ولا إله إلا الله، والله أكبر.',
      'اللهم أعني على ذكرك وشكرك وحسن عبادتك.'
    ],
    'آيات قرآنية':[
      '﴿فَإِنَّ مَعَ الْعُسْرِ يُسْرًا﴾\nالشرح: 5',
      '﴿وَقُل رَّبِّ زِدْنِي عِلْمًا﴾\nطه: 114',
      '﴿إِنَّ اللَّهَ مَعَ الصَّابِرِينَ﴾\nالبقرة: 153',
      '﴿وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ﴾\nالحديد: 4',
      '﴿لَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ﴾\nالزمر: 53',
      '﴿إِنَّ اللَّهَ يُحِبُّ الْمُحْسِنِينَ﴾\nالبقرة: 195',
      '﴿وَتَوَكَّلْ عَلَى اللَّهِ وَكَفَىٰ بِاللَّهِ وَكِيلًا﴾\nالأحزاب: 3',
      '﴿أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ﴾\nالرعد: 28',
      '﴿وَقُولُوا لِلنَّاسِ حُسْنًا﴾\nالبقرة: 83',
      '﴿إِنَّ مَعِيَ رَبِّي سَيَهْدِينِ﴾\nالشعراء: 62'
    ],
    'تهاني ومعايدات':[
      'كل عام وأنت بخير، جعل الله أيامك أفراحاً وطمأنينة.',
      'مبارك النجاح، ومنها للأعلى دائماً بإذن الله.',
      'عيد ميلاد سعيد، سنة جديدة مليئة بالخير والإنجاز.',
      'ألف مبروك التخرج، تعبك صار فرحة وفخراً.',
      'رمضان مبارك، تقبل الله صيامكم وقيامكم.',
      'عيدكم مبارك، أعاده الله عليكم بالصحة والسلام.',
      'مبارك المولود، جعله الله من مواليد السعادة.',
      'تستاهل كل خير، فرحتنا بنجاحك ما تنوصف.',
      'ربي يجعل بيتكم عامر بالمحبة والبركة.',
      'أجمل التهاني لبداية جديدة مليئة بالتوفيق.'
    ],
    'خذلان وفراق':[
      'أصعب الغياب أن يبقى الشخص حاضراً في التفاصيل.',
      'لا أعاتب من اختار الرحيل، لكنني أتعلم ألا أنتظر.',
      'بعض الوعود تنتهي قبل أن تبدأ الحكاية.',
      'لم يتغير الطريق؛ الذي تغير هو من كان يمشي معنا.',
      'أحياناً يكون حفظ الكرامة أصدق أشكال الوداع.',
      'ليس كل من ابتعد نسي، وليس كل من بقي وفيّاً.',
      'تعلّمت أن أصدّق المواقف أكثر من الكلمات.',
      'هناك أبواب نغلقها بهدوء كي لا نخسر أنفسنا.',
      'لا تكره الأمس؛ فقد علّمك من يستحق الغد.',
      'بعض النهايات رحمة لا نفهمها إلا متأخرين.'
    ],
    'نكت عراقية':[
      'واحد سأل صديقه: شنو أسرع شي بالدنيا؟ گله: الراتب… ينزل ويختفي!',
      'طالب گال للأستاذ: أستاذ نسيت الدفتر. گله: شنو جايب؟ گله: الذاكرة بس هم ناسيها.',
      'واحد اشترى ساعة ضد الماي… صار يسبح حتى يعرف الوقت.',
      'واحد فتح الثلاجة بالليل، لگه الجلي يگله: سد الباب بردانين!',
      'واحد راح للطبيب گله: كلما أشرب چاي عيني توجعني. گله: شيل الملعقة من الاستكان.',
      'واحد بخيل اشترى منبّه، خلاه يرن يم الجيران حتى يصحون بداله.',
      'مدرس سأل طالب: وين تقع الصين؟ گله: بالخرائط أستاذ.',
      'واحد نسى كلمة السر، كتب: نسيتها… الموقع گله: كلمة السر غلط!'
    ],
    'نكت خليجية':[
      'واحد قال لصاحبه: أنا أحب النظام. قال: طيب رتّب غرفتك. قال: لا تدخل في الخصوصيات!',
      'واحد اشترى سرير ذكي، كل ما ينام يقول له: قم حقق أحلامك!',
      'سألوا واحد: ليش تكلّم نفسك؟ قال: أستشير خبير وأسمع رأيه.',
      'واحد دخل اختبار ذكاء، طلع يقول: الحمد لله ما سألوني عن اسمي.',
      'واحد قال للثلاجة: ليش ساكتة؟ قالت: أنا باردة أعصاب.',
      'واحد حط جواله على الصامت، قام هو يتكلم بالإشارات.',
      'واحد اشترى كتاب عن الصبر، قال للبائع: استعجل عليّ أبي أخلصه.',
      'واحد قال لصاحبه: أنا ما أتأخر، أنا أعطي الناس فرصة يشتاقون.'
    ]
  };

  @override void dispose(){search.dispose();super.dispose();}
  List<MapEntry<String,String>> get visible {
    final q=search.text.trim().toLowerCase();
    return library.entries.where((e)=>category=='الكل'||e.key==category)
      .expand((e)=>e.value.map((v)=>MapEntry(e.key,v)))
      .where((e)=>q.isEmpty||e.value.toLowerCase().contains(q)||e.key.toLowerCase().contains(q)).toList();
  }
  Future<void> saveCard(String text) async {
    try {
      final key=GlobalKey();
      final bytes=await showDialog<Uint8List>(context:context,builder:(ctx)=>_CardExportDialog(text:text,exportKey:key));
      if(bytes==null)return;
      await Gal.putImageBytes(bytes,album:'ملتقى الأنمي');
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حفظ الصورة في المعرض')));
    } catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر حفظ الصورة: $e')));}
  }
  @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
    appBar:AppBar(title:const Text('مكتبة الأدب والعبارات'),actions:[
      IconButton(tooltip:'مصادر الشعر والاقتباسات',icon:const Icon(Icons.menu_book),onPressed:()=>showModalBottomSheet(context:context,builder:(_)=>Directionality(textDirection:TextDirection.rtl,child:ListView(shrinkWrap:true,children:[
        ListTile(title:const Text('الشعر العربي'),subtitle:const Text('مصدر للمراجعة والنسبة'),onTap:()=>launchUrl(Uri.parse('https://arabic-poetry.net/'))),
        ListTile(title:const Text('اقتباسات الديوان'),subtitle:const Text('تحقق من المصدر واسم القائل'),onTap:()=>launchUrl(Uri.parse('https://www.aldiwan.net/quotes.html'))),
      ])))),
    ]),
    body:Column(children:[
      Padding(padding:const EdgeInsets.all(12),child:TextField(controller:search,onChanged:(_)=>setState((){}),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'ابحث في الشعر والعبارات...',border:OutlineInputBorder()))),
      SizedBox(height:48,child:ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:8),children:categories.map((c)=>Padding(padding:const EdgeInsets.symmetric(horizontal:4),child:ChoiceChip(label:Text(c),selected:category==c,onSelected:(_)=>setState(()=>category=c)))).toList())),
      Expanded(child:visible.isEmpty?const Center(child:Text('ماكو نتائج')):ListView.builder(itemCount:visible.length,itemBuilder:(context,i){
        final item=visible[i];
        return Card(margin:const EdgeInsets.symmetric(horizontal:12,vertical:6),child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          Text(item.key,style:TextStyle(color:Theme.of(context).colorScheme.primary,fontWeight:FontWeight.bold,fontSize:12)),
          const SizedBox(height:10),
          SelectableText(item.value,textAlign:TextAlign.center,style:const TextStyle(fontSize:18,height:1.7,fontWeight:FontWeight.w600)),
          const SizedBox(height:10),
          Wrap(alignment:WrapAlignment.center,spacing:4,children:[
            IconButton(tooltip:'نسخ',onPressed:()=>Clipboard.setData(ClipboardData(text:item.value)),icon:const Icon(Icons.copy)),
            IconButton(tooltip:'مشاركة',onPressed:()=>ShareText.share(context,item.value),icon:const Icon(Icons.share)),
            IconButton(tooltip:'حفظ كصورة',onPressed:()=>saveCard(item.value),icon:const Icon(Icons.download)),
          ])
        ])));
      }))
    ])
  ));
}

class ShareText {
 static Future<void> share(BuildContext context,String text) async {
  await Clipboard.setData(ClipboardData(text:text));
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم نسخ النص؛ تگدر تشاركه من أي تطبيق')));
 }
}

class _CardExportDialog extends StatefulWidget {
 final String text; final GlobalKey exportKey;
 const _CardExportDialog({required this.text,required this.exportKey});
 @override State<_CardExportDialog> createState()=>_CardExportDialogState();
}
class _CardExportDialogState extends State<_CardExportDialog> {
 bool busy=false;
 Future<void> export() async {
  setState(()=>busy=true);
  try {
   await Future<void>.delayed(const Duration(milliseconds:80));
   final boundary=widget.exportKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
   final image=await boundary.toImage(pixelRatio:3);
   final data=await image.toByteData(format:ui.ImageByteFormat.png);
   if(mounted)Navigator.pop(context,data!.buffer.asUint8List());
  } catch(e){if(mounted){setState(()=>busy=false);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر تجهيز الصورة: $e')));}}
 }
 @override Widget build(BuildContext context)=>AlertDialog(
  title:const Text('معاينة بطاقة التحميل'),
  content:RepaintBoundary(key:widget.exportKey,child:Container(width:280,height:320,padding:const EdgeInsets.all(24),decoration:BoxDecoration(gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xFF171936),Color(0xFF6554D9),Color(0xFF259FC4)]),borderRadius:BorderRadius.circular(24)),child:Center(child:Text(widget.text,textAlign:TextAlign.center,style:const TextStyle(color:Colors.white,fontSize:23,height:1.6,fontWeight:FontWeight.bold))))),
  actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('إلغاء')),FilledButton(onPressed:busy?null:export,child:Text(busy?'جاري التجهيز':'حفظ في المعرض'))]
 );
}
