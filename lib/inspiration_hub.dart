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
  final tabs = const ['قصائد فصحى','شعر شعبي','اقتباسات','معايدات','أدعية'];
  static const themes = ['الأمل','الوطن','الصداقة','الأم','العلم','الكرامة','الحنين','الصبر','النجاح','الوفاء'];
  static const open = ['إذا أقبل الصبح استفاقت عزائمٌ','وفي القلب نورٌ لا تطفئه عاصفٌ','على درب أحلامي أسيرُ مؤمّلاً','ومن رحم الآلام يولدُ فرحُنا','أيا صاحِ إن المجد ليس هديةً','تعلّمْ فكم بالعلم تسمو نفوسُنا','إذا ضاق دربٌ فالأماني رحابةٌ','وما خاب قلبٌ باليقين تسلّحا','لأمي دعاءٌ في الفؤاد مردّدٌ','بلادي وإن طال المسير أحبّها'];
  static const close = ['ويزهر في درب المنى كلُّ غارسِ','ويشرق في ليل الشدائد كوكبُ','ونبلغُ بالإصرار أعلى المراتبِ','ويصبح بعد العسر يسرٌ قريبُ','فصُنْ عهدَ قلبٍ بالوفاء تزيّنا','فكن طالباً للعلم طول حياتِنا','فبعد ظلام الليل فجرٌ يلوحُ','ومن صبر الأيام نال المطالبا','فيا رب احفظها بكل تلطّفِ','ويحيا بها في القلب معنى المفاخرِ'];
  static const folkOpen = ['يا صاحبي لا تنحني لو جار بيك الوقت','خلّ الأمل بعيونك يضوي مثل نجمة ليل','يمّه دعائج بالضلوع وما يفارقني','يا ديرة العزّة تره حبّج سكن بالروح','الدرب لو يطول نمشيه بعزم وإصرار','ضحكتك ترد الروح لو كلشي تعب بيّه','لا تبيع الطيب لو دنياك صارت قاسية','من طيب أصلك ينزرع للناس ألف إحساس','يا قلب صابر لا تظن الفرح ناسيك','والما يحب بصدق ما يعرف معنى الوفه'];
  static const folkClose = ['وباجر يجي فرحٍ يبدّل كل هالضيج','والصبح يمسح دمعةٍ نامت على الخدّ','تبقين دعوة خير بگلبي وبكل أيامي','تبقين يا بغداد فخرٍ عالي الراس','والعسر مهما طال آخرته تنجلي','وأبقى أگول الحمد لله بكل حين','الطيب يبقى لو تغيّر كل هالناس','والذكرى الحلوة تعيش بداخل الإنسان','وتضحك سنين العمر من تسمع بشاير','والحب الصافي ما تغيّره المسافات'];
  static const qa = ['النجاح يبدأ بخطوة صغيرة','لا تقارن بدايتك بنهاية الآخرين','الكلمة الطيبة بابٌ للقلوب','الصبر قوة هادئة لا يراها الجميع','العلم نورٌ يوسّع أفق الحياة','الوفاء موقف قبل أن يكون كلاماً','الأمل نافذة لا تغلقها العواصف','احترامك للناس يعكس جمال روحك','كل تجربة درس يستحق التأمل','ازرع خيراً ولو في أرض بعيدة','القوة أن تنهض بعد كل عثرة','الوقت أثمن من أن يهدر في الندم','التواضع زينة المعرفة','سامح لتتحرر روحك من الثقل','الإنجاز وليد الاستمرار لا العجلة','كن سبباً في ابتسامة أحدهم','القلوب النقية لا تتقن الأذى','ابدأ بما تملك ومن حيث أنت','الهدوء جواب أحياناً','الأثر الطيب أطول عمراً من صاحبه'];
  static const qb = ['وكل يوم يمنحك فرصة جديدة.','فلا تستسلم قبل أن ترى النتيجة.','فاختر كلماتك كما تختار هداياك.','فالأيام تكشف معدن الصابرين.','واجعل التعلم عادة لا موسماً.','فالأفعال تحفظ ما تنساه الوعود.','فلا تسمح لليأس أن يقودك.','فالجمال الحقيقي يبدأ من الداخل.','فالنضج أن تفهم قبل أن تحكم.','فالعطاء يعود راحةً للقلب.','فالتعثر ليس نهاية الطريق.','فاصنع من لحظتك شيئاً جميلاً.','فالعقل المتواضع يتسع للحكمة.','فالحياة أقصر من حمل الضغائن.','فالثبات يصنع ما لا تصنعه القفزات.','فرب كلمة منك تغيّر يوماً كاملاً.','فالنقاء اختيار يومي.','فلا تنتظر الظروف المثالية.','فبعض الإجابات تحتاج صمتاً.','فليكن حضورك خيراً وغيابك دعاءً.'];
  late final List<String> classical = List.generate(150, (i) {
    final n=i%10;
    return 'في ' + themes[n] + '\n' + open[n] + '\n' + close[n] + '\nفامضِ ولا تخشَ الطريقَ فإنما\nبالصدق تُبنى في الحياة مآثرُ';
  });
  late final List<String> folk = List.generate(150, (i) {
    final n=i%10;
    return folkOpen[n] + '\n' + folkClose[n] + '\nوالعمر يمضي والوفه تبقى أثر\nوالطيب عنوان البشر لو طال السفر';
  });
  late final List<String> quotes = List.generate(400, (i) => qa[i%20] + '، ' + qb[((i~/20)+i%20)%20]);
  static const greetings = ['كل عام وأنت بخير، جعل الله أيامك فرحاً وطمأنينة، وكتب لك عاماً أجمل من كل ما مضى.','عيد ميلاد سعيد! أتمنى لك صحة لا تزول، وقلباً مطمئناً، وأحلاماً تتحقق واحدة تلو الأخرى.','مبارك عليك العيد، أعاده الله عليك وعلى أحبابك بالخير واليمن والبركات.','ألف مبروك النجاح، تستحق كل خير، ومنها إلى أعلى المراتب والإنجازات.','مبارك التخرج، جعل الله علمك نافعاً ومستقبلك مشرقاً وخطواتك موفقة.','بارك الله لكما وبارك عليكما وجمع بينكما في خير، وأدام المودة والرحمة.','سلامتك، أسأل الله أن يلبسك ثوب الصحة والعافية وأن يطمئن قلبك.','مبارك المولود، جعله الله من مواليد السعادة ومن الصالحين البارين.'];
  static const prayers = ['اللهم إني أسألك راحةً تسكن بها القلوب، وفرجاً تمحو به الهموم، ورزقاً يملأ الحياة بركة.','اللهم اغفر لنا ولوالدينا، وارحمهما كما ربيانا صغاراً، واجزهما عنا خير الجزاء.','يا رب اشرح صدورنا، ويسّر أمورنا، واكتب لنا الخير حيث كان ثم أرضنا به.','اللهم احفظ أهلنا وأحبتنا، وأدم عليهم الصحة والعافية والأمان.','اللهم ارزقنا قلباً شاكراً ولساناً ذاكراً وعملاً صالحاً متقبلاً.','ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة وقنا عذاب النار.','اللهم اجعل القادم أجمل، وافتح لنا أبواب رحمتك وفضلك.','اللهم اشفِ كل مريض، وارحم كل ميت، وفرّج هم كل مهموم.'];
  List<String> get items => switch(category) {'قصائد فصحى'=>classical,'شعر شعبي'=>folk,'اقتباسات'=>quotes,'معايدات'=>greetings,_=>prayers};
  @override Widget build(BuildContext context) => Directionality(textDirection:TextDirection.rtl,child:Scaffold(
    appBar:AppBar(title:const Text('مكتبة الملتقى'),backgroundColor:_ink,foregroundColor:Colors.white),
    body:Container(decoration:const BoxDecoration(gradient:LinearGradient(begin:Alignment.topRight,end:Alignment.bottomLeft,colors:[Color(0xFFF7F5FF),Color(0xFFE9F4FA)])),child:Column(children:[
      Container(width:double.infinity,padding:const EdgeInsets.all(18),decoration:const BoxDecoration(gradient:LinearGradient(colors:[_ink,_violet,Color(0xFF168E9B)]),borderRadius:BorderRadius.vertical(bottom:Radius.circular(26))),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('مساحة للكلمة الجميلة ✨',style:TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.bold)),SizedBox(height:5),Text('قصائد وعبارات ومعايدات وأدعية تجمعنا على الخير',style:TextStyle(color:Colors.white70))])),
      SizedBox(height:62,child:ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:10,vertical:10),children:tabs.map((t)=>Padding(padding:const EdgeInsets.symmetric(horizontal:4),child:ChoiceChip(label:Text(t),selected:category==t,onSelected:(_)=>setState(()=>category=t),selectedColor:_violet,labelStyle:TextStyle(color:category==t?Colors.white:_ink,fontWeight:FontWeight.bold)))).toList())),
      Expanded(child:ListView.separated(padding:const EdgeInsets.all(14),itemCount:items.length,separatorBuilder:(_,__)=>const SizedBox(height:9),itemBuilder:(context,i)=>Card(elevation:1,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(17)),child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[Icon(category=='اقتباسات'?Icons.format_quote:category=='أدعية'?Icons.volunteer_activism:category=='معايدات'?Icons.card_giftcard:Icons.auto_awesome,color:_violet),const SizedBox(width:8),Text(category,style:const TextStyle(color:_violet,fontWeight:FontWeight.bold)),const Spacer(),Text((i+1).toString()+' / '+items.length.toString(),style:const TextStyle(color:Colors.grey,fontSize:12))]),
        const SizedBox(height:9),SelectableText(items[i],style:const TextStyle(fontSize:17,height:1.8,color:_ink)),
        Align(alignment:Alignment.centerLeft,child:IconButton(tooltip:'نسخ',onPressed:()=>Clipboard.setData(ClipboardData(text:items[i])).then((_)=>ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم نسخ النص')))),icon:const Icon(Icons.copy_rounded,color:_violet)))
      ]))))),
    ])),
  ));
}
