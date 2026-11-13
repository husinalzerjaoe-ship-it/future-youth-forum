import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _ink = Color(0xFF171936);
const _violet = Color(0xFF6554D9);

class InspirationHubPage extends StatefulWidget {
  const InspirationHubPage({super.key});
  @override State<InspirationHubPage> createState() => _InspirationHubPageState();
}
class _InspirationHubPageState extends State<InspirationHubPage> {
  String category = 'قصائد فصحى';
  final tabs = const ['قصائد فصحى','شعر شعبي','اقتباسات','معايدات','أدعية','صباحيات','مسائيات'];
  static const themes = ['الأمل','الوطن','الصداقة','الأم','العلم','الكرامة','الحنين','الصبر','النجاح','الوفاء'];
  static const open = ['إذا أقبل الصبح استفاقت عزائمٌ','وفي القلب نورٌ لا تطفئه عاصفٌ','على درب أحلامي أسيرُ مؤمّلاً','ومن رحم الآلام يولدُ فرحُنا','أيا صاحِ إن المجد ليس هديةً','تعلّمْ فكم بالعلم تسمو نفوسُنا','إذا ضاق دربٌ فالأماني رحابةٌ','وما خاب قلبٌ باليقين تسلّحا','لأمي دعاءٌ في الفؤاد مردّدٌ','بلادي وإن طال المسير أحبّها'];
  static const close = ['ويزهر في درب المنى كلُّ غارسِ','ويشرق في ليل الشدائد كوكبُ','ونبلغُ بالإصرار أعلى المراتبِ','ويصبح بعد العسر يسرٌ قريبُ','فصُنْ عهدَ قلبٍ بالوفاء تزيّنا','فكن طالباً للعلم طول حياتِنا','فبعد ظلام الليل فجرٌ يلوحُ','ومن صبر الأيام نال المطالبا','فيا رب احفظها بكل تلطّفِ','ويحيا بها في القلب معنى المفاخرِ'];
  static const folkOpen = ['يا صاحبي لا تنحني لو جار بيك الوقت','خلّ الأمل بعيونك يضوي مثل نجمة ليل','يمّه دعائج بالضلوع وما يفارقني','يا ديرة العزّة تره حبّج سكن بالروح','الدرب لو يطول نمشيه بعزم وإصرار','ضحكتك ترد الروح لو كلشي تعب بيّه','لا تبيع الطيب لو دنياك صارت قاسية','من طيب أصلك ينزرع للناس ألف إحساس','يا قلب صابر لا تظن الفرح ناسيك','والما يحب بصدق ما يعرف معنى الوفه'];
  static const folkClose = ['وباجر يجي فرحٍ يبدّل كل هالضيج','والصبح يمسح دمعةٍ نامت على الخدّ','تبقين دعوة خير بگلبي وبكل أيامي','تبقين يا بغداد فخرٍ عالي الراس','والعسر مهما طال آخرته تنجلي','وأبقى أگول الحمد لله بكل حين','الطيب يبقى لو تغيّر كل هالناس','والذكرى الحلوة تعيش بداخل الإنسان','وتضحك سنين العمر من تسمع بشاير','والحب الصافي ما تغيّره المسافات'];
  static const qa = ['النجاح يبدأ بخطوة صغيرة','لا تقارن بدايتك بنهاية الآخرين','الكلمة الطيبة بابٌ للقلوب','الصبر قوة هادئة لا يراها الجميع','العلم نورٌ يوسّع أفق الحياة','الوفاء موقف قبل أن يكون كلاماً','الأمل نافذة لا تغلقها العواصف','احترامك للناس يعكس جمال روحك','كل تجربة درس يستحق التأمل','ازرع خيراً ولو في أرض بعيدة','القوة أن تنهض بعد كل عثرة','الوقت أثمن من أن يهدر في الندم','التواضع زينة المعرفة','سامح لتتحرر روحك من الثقل','الإنجاز وليد الاستمرار لا العجلة','كن سبباً في ابتسامة أحدهم','القلوب النقية لا تتقن الأذى','ابدأ بما تملك ومن حيث أنت','الهدوء جواب أحياناً','الأثر الطيب أطول عمراً من صاحبه'];
  static const qb = ['وكل يوم يمنحك فرصة جديدة.','فلا تستسلم قبل أن ترى النتيجة.','فاختر كلماتك كما تختار هداياك.','فالأيام تكشف معدن الصابرين.','واجعل التعلم عادة لا موسماً.','فالأفعال تحفظ ما تنساه الوعود.','فلا تسمح لليأس أن يقودك.','فالجمال الحقيقي يبدأ من الداخل.','فالنضج أن تفهم قبل أن تحكم.','فالعطاء يعود راحةً للقلب.','فالتعثر ليس نهاية الطريق.','فاصنع من لحظتك شيئاً جميلاً.','فالعقل المتواضع يتسع للحكمة.','فالحياة أقصر من حمل الضغائن.','فالثبات يصنع ما لا تصنعه القفزات.','فرب كلمة منك تغيّر يوماً كاملاً.','فالنقاء اختيار يومي.','فلا تنتظر الظروف المثالية.','فبعض الإجابات تحتاج صمتاً.','فليكن حضورك خيراً وغيابك دعاءً.'];
  static const classicalEnds = ['وفي كل حرفٍ للمعاني منازلُ','وتحرس أحلامَ الفتى المتفائلِ','وتبقى على مرّ السنين رسائلُ','ويحلو بصدق العزم صعب المسالكِ','وتسمو النفوسُ بطيب فعلٍ ونائلِ','ويشرق في وجه الحياة تفاؤلُ','وتنمو بذور الخير رغم العواصفِ','ويحيا رجاء المرء رغم التحوّلِ','وتبقى خطانا في الدروب دلائلُ','ويكتب تاريخ المروءة فاعلُ','ويزهر غصن الصبر بعد الذبولِ','وتسمو المعالي بالقلوب الأصائلِ','ويغدو غدٌ بالحب أبهى وأكملُ','ويحفظنا الرحمن خير الحوافظِ','ويشهد هذا العمر صدق المحاولِ'];
  static const folkEnds = ['والطيب يبقى لو تغيّر زمانك','وباجر تضحكلك لياليك الحزينة','والفرح يطرق باب صبرك من بعيد','وتبقى عزيز النفس عالي المقام','ومن بعد ضيقة يجي فرج الكريم','والله كريم وما يضيّع تعب روح','والعشرة تبقى لو تباعدنه الدروب','والذكرى الحلوة تعيش بكل مكان','وترد الروح ضحكة أحبابك','والخير يرجعلك ولو بعد حين','وتبقى المحبة أكبر من المسافة','والعمر يحلى بالقلوب الصافية','وكل جرح بمرور الأيام يطيب','وتبقى المواقف شاهدٍ للوفي','والأمل بعيونك يظل ما ينطفي'];
  late final List<String> classical = List.generate(150, (i) {
    final n=i%10;
    return 'في ' + themes[n] + '\n' + open[n] + '\n' + close[n] + '\n' + classicalEnds[i % classicalEnds.length] + '\nفامضِ ولا تخشَ الطريقَ فإنما\nبالصدق تُبنى في الحياة مآثرُ';
  });
  late final List<String> folk = List.generate(150, (i) {
    final n=i%10;
    return folkOpen[n] + '\n' + folkClose[n] + '\n' + folkEnds[i % folkEnds.length] + '\nوالعمر يمضي والوفه تبقى أثر\nوالطيب عنوان البشر لو طال السفر';
  });
  late final List<String> quotes = List.generate(400, (i) => qa[i%20] + '، ' + qb[((i~/20)+i%20)%20]);
  static const greetings = ['كل عام وأنت بخير، جعل الله أيامك فرحاً وطمأنينة، وكتب لك عاماً أجمل من كل ما مضى.','عيد ميلاد سعيد! أتمنى لك صحة لا تزول، وقلباً مطمئناً، وأحلاماً تتحقق واحدة تلو الأخرى.','مبارك عليك العيد، أعاده الله عليك وعلى أحبابك بالخير واليمن والبركات.','ألف مبروك النجاح، تستحق كل خير، ومنها إلى أعلى المراتب والإنجازات.','مبارك التخرج، جعل الله علمك نافعاً ومستقبلك مشرقاً وخطواتك موفقة.','بارك الله لكما وبارك عليكما وجمع بينكما في خير، وأدام المودة والرحمة.','سلامتك، أسأل الله أن يلبسك ثوب الصحة والعافية وأن يطمئن قلبك.','مبارك المولود، جعله الله من مواليد السعادة ومن الصالحين البارين.'];
  static const prayers = ['اللهم إني أسألك راحةً تسكن بها القلوب، وفرجاً تمحو به الهموم، ورزقاً يملأ الحياة بركة.','اللهم اغفر لنا ولوالدينا، وارحمهما كما ربيانا صغاراً، واجزهما عنا خير الجزاء.','يا رب اشرح صدورنا، ويسّر أمورنا، واكتب لنا الخير حيث كان ثم أرضنا به.','اللهم احفظ أهلنا وأحبتنا، وأدم عليهم الصحة والعافية والأمان.','اللهم ارزقنا قلباً شاكراً ولساناً ذاكراً وعملاً صالحاً متقبلاً.','ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة وقنا عذاب النار.','اللهم اجعل القادم أجمل، وافتح لنا أبواب رحمتك وفضلك.','اللهم اشفِ كل مريض، وارحم كل ميت، وفرّج هم كل مهموم.'];
  static const mornings = [
    'صباح الخير، جعل الله هذا الصباح بداية خير وراحة بال وأخبار تسرّ القلب.',
    'اللهم مع إشراقة هذا اليوم ارزقنا توفيقاً يرافق خطواتنا وطمأنينة تسكن قلوبنا.',
    'صباح الأمل؛ لا تؤجل ابتسامتك، فقد يحمل هذا اليوم ما انتظرته طويلاً.',
    'اللهم افتح لنا أبواب رزقك ورحمتك، وبارك لنا في أهلنا وأوقاتنا وأعمالنا.',
    'صباح الورد للقلوب الطيبة التي تجعل الحياة ألطف بحضورها.',
    'ابدأ يومك بنية طيبة، وكلمة جميلة، وخطوة تقرّبك من حلمك.',
    'اللهم اجعل هذا اليوم شاهداً لنا بالخير، لا علينا، واكتب لنا فيه أجمل الأقدار.',
    'صباح التفاؤل؛ مهما تأخر الفرج، يبقى لطف الله أوسع من كل انتظار.',
    'أسعد الله صباحكم بنور الإيمان وراحة النفس وبركة العمر.',
    'كل صباح فرصة جديدة لنكون أفضل مما كنا عليه بالأمس.'
  ];
  static const evenings = [
    'مساء الخير، جعل الله مساءكم سكينة ورضا وأحاديث تبهج القلب.',
    'اللهم في هذا المساء أرح قلوباً لا يعلم تعبها إلا أنت، واكتب لها فرجاً قريباً.',
    'مساء الهدوء لكل من أنهكه النهار، غداً بإذن الله يحمل فرصة جديدة.',
    'أمسية طيبة مليئة بالمحبة، وقلوب لا تعرف إلا الوفاء.',
    'اللهم احفظ أحبتنا أينما كانوا، وأبعد عنهم الهم والحزن وسوء الأقدار.',
    'في نهاية اليوم، تذكّر أن المحاولة بحد ذاتها خطوة تستحق التقدير.',
    'مساؤكم دعاء مستجاب، ورزق واسع، وخبر جميل يطرق أبوابكم.',
    'اتركوا تعب اليوم خلفكم، وناموا بقلوب مطمئنة بحسن تدبير الله.',
    'مساء المحبة لمن يزرعون الفرح بكلمة ولا ينتظرون مقابلاً.',
    'اللهم اختم يومنا بعفوك ورضاك، واجعل غدنا أجمل مما نرجو.'
  ];
  List<String> get items => switch(category) {'قصائد فصحى'=>classical,'شعر شعبي'=>folk,'اقتباسات'=>quotes,'معايدات'=>greetings,'أدعية'=>prayers,'صباحيات'=>mornings,_=>evenings};
  @override Widget build(BuildContext context) { final cs=Theme.of(context).colorScheme; return Directionality(textDirection:TextDirection.rtl,child:Scaffold(
    appBar:AppBar(title:const Text('مكتبة الملتقى')),
    body:Container(color:cs.surface,child:Column(children:[
      Container(width:double.infinity,padding:const EdgeInsets.all(18),decoration:const BoxDecoration(gradient:LinearGradient(colors:[_ink,_violet,Color(0xFF168E9B)]),borderRadius:BorderRadius.vertical(bottom:Radius.circular(26))),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('مساحة للكلمة الجميلة ✨',style:TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.bold)),SizedBox(height:5),Text('قصائد وعبارات ومعايدات وأدعية تجمعنا على الخير',style:TextStyle(color:Colors.white70))])),
      SizedBox(height:62,child:ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:10,vertical:10),children:tabs.map((t)=>Padding(padding:const EdgeInsets.symmetric(horizontal:4),child:ChoiceChip(label:Text(t),selected:category==t,onSelected:(_)=>setState(()=>category=t),selectedColor:cs.primary,labelStyle:TextStyle(color:category==t?cs.onPrimary:cs.onSurface,fontWeight:FontWeight.bold)))).toList())),
      Expanded(child:ListView.separated(padding:const EdgeInsets.all(14),itemCount:items.length,separatorBuilder:(_,__)=>const SizedBox(height:9),itemBuilder:(context,i)=>Card(color:cs.surfaceContainerLow,elevation:1,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(17)),child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[Icon(category=='اقتباسات'?Icons.format_quote:category=='أدعية'?Icons.volunteer_activism:category=='معايدات'?Icons.card_giftcard:category=='صباحيات'?Icons.wb_sunny:category=='مسائيات'?Icons.nights_stay:Icons.auto_awesome,color:cs.primary),const SizedBox(width:8),Text(category,style:TextStyle(color:cs.primary,fontWeight:FontWeight.bold)),const Spacer(),Text((i+1).toString()+' / '+items.length.toString(),style:const TextStyle(color:Colors.grey,fontSize:12))]),
        const SizedBox(height:9),SelectableText(items[i],style:TextStyle(fontSize:18,height:1.9,color:cs.onSurface,fontWeight:FontWeight.w500)),
        Align(alignment:Alignment.centerLeft,child:IconButton(tooltip:'نسخ',onPressed:()=>Clipboard.setData(ClipboardData(text:items[i])).then((_)=>ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم نسخ النص')))),icon:Icon(Icons.copy_rounded,color:cs.primary)))
      ]))))),
    ])),
  )); }
}
