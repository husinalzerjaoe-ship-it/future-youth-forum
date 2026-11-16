import 'dart:math';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'multiplayer_arcade.dart';
import 'social_party_games.dart';
import 'board_games.dart';
import 'arcade_minigames.dart';
import 'arcade_penalty.dart';
import 'friends_quiz.dart';
import 'friends_battle_arena.dart';
import 'future_arcade.dart';

const gameInk=Color(0xFF171936), gameViolet=Color(0xFF6554D9);
final gameDb=FirebaseFirestore.instance;
String get gameUid=>FirebaseAuth.instance.currentUser!.uid;

class _GameEntry {
  final String title, subtitle, tag;
  final IconData icon;
  final Widget page;
  final Color color;
  const _GameEntry(this.title, this.subtitle, this.tag, this.icon, this.page, this.color);
}
class GameCenterPage extends StatefulWidget {
  const GameCenterPage({super.key});
  @override State<GameCenterPage> createState() => _GameCenterPageState();
}
class _GameCenterPageState extends State<GameCenterPage> {
  final TextEditingController _search = TextEditingController();
  String _filter = 'الكل';
  late final List<_GameEntry> _games = [
    _GameEntry('صالة ألعاب 2D + 3D','10 ألعاب جديدة • تحديات فردية وثنائية','جديد',Icons.videogame_asset_rounded,const ArcadeGamesHubScreen(),const Color(0xFF38D9E6)),
    _GameEntry('Future Arcade','14 لعبة جديدة • تحديات • ألعاب 2D','جديد',Icons.sports_esports_rounded,const FutureArcadePage(),const Color(0xFF13A89E)),
    _GameEntry('كنز الأصدقاء 2D','خريطة مباشرة • جواهر • غرف ودعوات','2D أونلاين',Icons.map_rounded,const TreasureLobbyPage(),const Color(0xFF13A89E)),
    _GameEntry('ساحة منافسات الأصدقاء','12 تصنيف أسئلة • نقاط • جولات','تحديات',Icons.emoji_events_rounded,const FriendsBattleArenaPage(),const Color(0xFF6554D9)),
    _GameEntry('مسابقة الأصدقاء المباشرة','2–4 لاعبين • رمز غرفة • ترتيب','أونلاين',Icons.groups_rounded,const FriendsQuizPage(),const Color(0xFF2878C7)),
    _GameEntry('إكس أو أونلاين','تحدّ صديقك بغرفة خاصة','أونلاين',Icons.grid_3x3_rounded,const MultiplayerArcadePage(),const Color(0xFF0C9C8B)),
    _GameEntry('ألعاب السهرة','الجاسوس • الذئب • الرسم • الخداع','جماعية',Icons.nightlife_rounded,const SocialPartyGamesPage(),const Color(0xFFB65BC8)),
    _GameEntry('ألعاب الطاولة','الدومينو والدامة لشخصين','جماعية',Icons.extension_rounded,const BoardGamesPage(),const Color(0xFFB77A32)),
    _GameEntry('ألعاب الذكاء','ذاكرة • حروف • تحديات سريعة','فردية',Icons.psychology_alt_rounded,const ArcadeMiniGamesPage(),const Color(0xFF4779B8)),
    _GameEntry('ضربات الجزاء','سدّد وتغلّب على الحارس','فردية',Icons.sports_soccer_rounded,const PenaltyShootoutPage(),const Color(0xFF27956C)),
    _GameEntry('معلومات عامة','اختبر معلوماتك بمراحل متنوعة','أسئلة',Icons.public_rounded,const _QuizGame(category:'general'),const Color(0xFF4779B8)),
    _GameEntry('تحدي كرة القدم','أندية • بطولات • منتخبات','أسئلة',Icons.sports_soccer_rounded,const _QuizGame(category:'football'),const Color(0xFF27956C)),
    _GameEntry('من هو اللاعب؟','خمن اللاعب من التلميحات','أسئلة',Icons.person_search_rounded,const _QuizGame(category:'player'),const Color(0xFFB77A32)),
    _GameEntry('تحدي السرعة','جاوب قبل انتهاء الوقت','أسئلة',Icons.bolt_rounded,const _QuizGame(category:'speed'),const Color(0xFFD17A32)),
    _GameEntry('تحدي الأعلام','اعرف الدولة من علمها','أسئلة',Icons.flag_rounded,const _QuizGame(category:'flags'),const Color(0xFF0C9C8B)),
    _GameEntry('عالم الأنمي','شخصيات وأحداث وأنميات','أسئلة',Icons.animation_rounded,const _QuizGame(category:'anime'),const Color(0xFFB65BC8)),
    _GameEntry('شعارات الأندية','الألوان والألقاب والفرق','أسئلة',Icons.shield_rounded,const _QuizGame(category:'clubs'),const Color(0xFF2878C7)),
    _GameEntry('تحدي العلوم','فيزياء • كيمياء • أحياء','أسئلة',Icons.science_rounded,const _QuizGame(category:'science'),const Color(0xFF4779B8)),
    _GameEntry('ذاكرة العراق','حضارات • مدن • تاريخ','أسئلة',Icons.account_balance_rounded,const _QuizGame(category:'iraq'),const Color(0xFFB77A32)),
    _GameEntry('رحلة حول العالم','عواصم • جغرافيا • معالم','أسئلة',Icons.public_rounded,const _QuizGame(category:'geography'),const Color(0xFF0C9C8B)),
    _GameEntry('تحدي التقنية','إنترنت • برمجة • أمان رقمي','أسئلة',Icons.memory_rounded,const _QuizGame(category:'technology'),const Color(0xFF2878C7)),
    _GameEntry('مملكة الحيوانات','كائنات • بيئات • عجائب','أسئلة',Icons.pets_rounded,const _QuizGame(category:'animals'),const Color(0xFF27956C)),
    _GameEntry('أسرار الفضاء','كواكب • نجوم • مجرات','أسئلة',Icons.rocket_launch_rounded,const _QuizGame(category:'space'),const Color(0xFF6554D9)),
  ];
  @override void dispose() { _search.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final games = _games.where((g) {
      final matchesText = query.isEmpty || (g.title + ' ' + g.subtitle + ' ' + g.tag).toLowerCase().contains(query);
      final matchesFilter = _filter == 'الكل' ||
        (_filter == 'أونلاين' && (g.tag.contains('أونلاين') || g.tag == 'جماعية')) ||
        (_filter == '2D' && g.tag.contains('2D')) ||
        (_filter == 'أسئلة' && g.tag == 'أسئلة') ||
        (_filter == 'فردية' && g.tag == 'فردية');
      return matchesText && matchesFilter;
    }).toList();
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(
      appBar:AppBar(title:const Text('مركز الألعاب'),centerTitle:true),
      body:CustomScrollView(slivers:[
        SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.fromLTRB(14,8,14,8),child:Container(
          padding:const EdgeInsets.all(20),
          decoration:BoxDecoration(borderRadius:BorderRadius.circular(26),gradient:const LinearGradient(begin:Alignment.topRight,end:Alignment.bottomLeft,colors:[Color(0xFF171936),Color(0xFF6554D9),Color(0xFF13A89E)]),boxShadow:[BoxShadow(color:gameViolet.withValues(alpha:.22),blurRadius:18,offset:const Offset(0,8))]),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[Container(width:52,height:52,decoration:BoxDecoration(color:Colors.white.withValues(alpha:.16),borderRadius:BorderRadius.circular(17)),child:const Icon(Icons.sports_esports_rounded,color:Colors.white,size:30)),const Spacer(),const Text('PLAY • COMPETE • WIN',style:TextStyle(color:Colors.white70,fontWeight:FontWeight.w800,letterSpacing:1))]),
            const SizedBox(height:15),
            const Text('اللعب أحلى ويّا الأصدقاء 🎮',style:TextStyle(color:Colors.white,fontSize:23,fontWeight:FontWeight.w900)),
            const SizedBox(height:5),
            const Text('تحديات، ألعاب جماعية، أسئلة ومغامرات ثنائية الأبعاد',style:TextStyle(color:Colors.white70,height:1.5)),
            const SizedBox(height:16),
            Row(children:[_HeroStat(value:_games.length.toString(),label:'لعبة'),const SizedBox(width:9),const _HeroStat(value:'24',label:'تصنيف أسئلة'),const SizedBox(width:9),const _HeroStat(value:'2D',label:'مغامرات')]),
            const SizedBox(height:16),
            SizedBox(width:double.infinity,child:FilledButton.icon(style:FilledButton.styleFrom(backgroundColor:Colors.white,foregroundColor:gameInk,padding:const EdgeInsets.symmetric(vertical:13)),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const TreasureLobbyPage())),icon:const Icon(Icons.map_rounded),label:const Text('ابدأ مغامرة الكنز 2D',style:TextStyle(fontWeight:FontWeight.w900)))),
          ]),
        ))),
        SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.fromLTRB(14,8,14,4),child:TextField(controller:_search,onChanged:(_)=>setState((){}),decoration:InputDecoration(hintText:'ابحث عن لعبة أو تحدٍّ...',prefixIcon:const Icon(Icons.search_rounded),suffixIcon:_search.text.isEmpty?null:IconButton(icon:const Icon(Icons.close),onPressed:(){_search.clear();setState((){});}),filled:true,border:OutlineInputBorder(borderRadius:BorderRadius.circular(17),borderSide:BorderSide.none))))),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 54,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              scrollDirection: Axis.horizontal,
              children: ['الكل', 'أونلاين', '2D', 'أسئلة', 'فردية']
                  .map((f) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ))
                  .toList(),
            ),
          ),
        ),
        SliverPadding(padding:const EdgeInsets.fromLTRB(14,8,14,24),sliver:games.isEmpty?const SliverToBoxAdapter(child:Padding(padding:EdgeInsets.all(35),child:Center(child:Text('ما لقينا لعبة بهذا الاسم. جرّب كلمة ثانية.')))):SliverGrid(gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,mainAxisSpacing:11,crossAxisSpacing:11,childAspectRatio:.91),delegate:SliverChildBuilderDelegate((context,index)=>_GameCard(game:games[index]),childCount:games.length))),
      ]),
    ));
  }
}
class _HeroStat extends StatelessWidget {
  final String value,label;
  const _HeroStat({required this.value,required this.label});
  @override Widget build(BuildContext context)=>Expanded(child:Container(padding:const EdgeInsets.symmetric(vertical:9,horizontal:7),decoration:BoxDecoration(color:Colors.white.withValues(alpha:.13),borderRadius:BorderRadius.circular(13)),child:Column(children:[Text(value,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:17)),Text(label,style:const TextStyle(color:Colors.white70,fontSize:11))])));
}
class _GameCard extends StatelessWidget {
  final _GameEntry game;
  const _GameCard({required this.game});
  @override Widget build(BuildContext context)=>Material(color:Theme.of(context).colorScheme.surface,borderRadius:BorderRadius.circular(21),child:InkWell(borderRadius:BorderRadius.circular(21),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>game.page)),child:Container(padding:const EdgeInsets.all(13),decoration:BoxDecoration(borderRadius:BorderRadius.circular(21),border:Border.all(color:Theme.of(context).dividerColor.withValues(alpha:.35)),boxShadow:[BoxShadow(color:game.color.withValues(alpha:.07),blurRadius:12,offset:const Offset(0,5))]),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[Container(width:45,height:45,decoration:BoxDecoration(color:game.color.withValues(alpha:.13),borderRadius:BorderRadius.circular(15)),child:Icon(game.icon,color:game.color,size:25)),const Spacer(),Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),decoration:BoxDecoration(color:game.color.withValues(alpha:.11),borderRadius:BorderRadius.circular(20)),child:Text(game.tag,style:TextStyle(color:game.color,fontSize:10,fontWeight:FontWeight.w800)))]),
    const Spacer(),
    Text(game.title,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:14.5)),
    const SizedBox(height:5),
    Text(game.subtitle,maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:11.5,color:Theme.of(context).colorScheme.onSurfaceVariant,height:1.3)),
    const SizedBox(height:7),
    Row(children:[Text('العب الآن',style:TextStyle(color:game.color,fontWeight:FontWeight.w900,fontSize:12)),const Spacer(),Icon(Icons.arrow_back_rounded,color:game.color,size:17)]),
  ]))));
}
class _Question {final String q;final List<String> a;final int correct;final String why;const _Question(this.q,this.a,this.correct,this.why);}
const _general=[
 _Question('ما عاصمة العراق؟',['البصرة','بغداد','أربيل','الموصل'],1,'بغداد عاصمة جمهورية العراق.'),
 _Question('كم عدد قارات العالم؟',['5','6','7','8'],2,'القارات سبع.'),
 _Question('ما الكوكب الأحمر؟',['المريخ','الزهرة','زحل','عطارد'],0,'المريخ يُعرف بالكوكب الأحمر.'),
 _Question('كم ضلعاً للمثلث؟',['2','3','4','5'],1,'للمثلث ثلاثة أضلاع.'),
 _Question('ما أكبر محيط؟',['الأطلسي','الهندي','الهادئ','المتجمد'],2,'المحيط الهادئ هو الأكبر.'),
 _Question('ما لغة البرازيل الرسمية؟',['الإسبانية','البرتغالية','الفرنسية','الإنجليزية'],1,'البرتغالية هي اللغة الرسمية.'),
 _Question('كم دقيقة في الساعة؟',['30','45','60','90'],2,'الساعة ستون دقيقة.'),
 _Question('ما الحيوان الملقب بسفينة الصحراء؟',['الحصان','الجمل','الغزال','الفيل'],1,'الجمل يتحمل ظروف الصحراء.'),
 _Question('ما ناتج 12 × 8؟',['86','92','96','108'],2,'12 في 8 تساوي 96.'),
 _Question('ما الغاز الذي تمتصه النباتات؟',['الأوكسجين','النيتروجين','ثاني أوكسيد الكربون','الهيدروجين'],2,'تستخدم النباتات ثاني أوكسيد الكربون في البناء الضوئي.'),
 _Question('ما عاصمة اليابان؟',['كيوتو','طوكيو','أوساكا','ناغويا'],1,'طوكيو عاصمة اليابان.'),
 _Question('كم عدد أيام السنة الكبيسة؟',['364','365','366','367'],2,'السنة الكبيسة 366 يوماً.'),
 _Question('ما أسرع حيوان بري؟',['الأسد','الفهد','النمر','الحصان'],1,'الفهد هو الأسرع برياً.'),
 _Question('ما أكبر عضو في جسم الإنسان؟',['القلب','الكبد','الجلد','الرئة'],2,'الجلد أكبر أعضاء الجسم.'),
 _Question('ما عاصمة مصر؟',['الإسكندرية','القاهرة','الأقصر','أسوان'],1,'القاهرة عاصمة مصر.'),
 _Question('كم لوناً في قوس قزح تقليدياً؟',['5','6','7','8'],2,'الألوان سبعة.'),
 _Question('ما وحدة قياس شدة التيار؟',['الفولت','الأمبير','الواط','الأوم'],1,'تقاس شدة التيار بالأمبير.'),
 _Question('أي معدن سائل بدرجة حرارة الغرفة؟',['الحديد','الزئبق','النحاس','الذهب'],1,'الزئبق معدن سائل في الظروف المعتادة.'),
 _Question('ما عاصمة فرنسا؟',['روما','مدريد','باريس','برلين'],2,'باريس عاصمة فرنسا.'),
 _Question('كم عدد حروف اللغة العربية؟',['26','27','28','29'],2,'حروف العربية 28 حرفاً.'),
];
const _science=[
 _Question('ما وحدة قياس القوة؟',['الجول','النيوتن','الواط','الأمبير'],1,'تقاس القوة بالنيوتن.'),
 _Question('أي جزء من الخلية يحمل معظم المادة الوراثية؟',['النواة','الغشاء','السيتوبلازم','الجدار'],0,'توجد معظم المادة الوراثية في النواة.'),
 _Question('ما الرمز الكيميائي للأوكسجين؟',['Ox','O','Og','On'],1,'رمز الأوكسجين O.'),
 _Question('ما اسم تحول السائل إلى غاز؟',['التجمد','التكاثف','التبخر','الترسب'],2,'يسمى التحول إلى غاز بالتبخر.'),
 _Question('أي عضو يضخ الدم في جسم الإنسان؟',['الرئة','القلب','الكبد','الكلى'],1,'القلب يضخ الدم عبر الأوعية.'),
 _Question('ما أقرب كوكب إلى الشمس؟',['الأرض','الزهرة','عطارد','المريخ'],2,'عطارد أقرب الكواكب إلى الشمس.')
];
const _iraq=[
 _Question('ما النهران الرئيسيان في العراق؟',['النيل والفرات','دجلة والفرات','دجلة والأردن','الفرات والكارون'],1,'دجلة والفرات هما النهران الرئيسيان.'),
 _Question('ما اسم ملحمة بلاد الرافدين الشهيرة؟',['الإلياذة','جلجامش','الشاهنامة','الأوديسة'],1,'ملحمة جلجامش من أشهر النصوص القديمة.'),
 _Question('أي مدينة عراقية ارتبطت بالزقورة الشهيرة؟',['أور','البصرة','دهوك','كربلاء'],0,'زقورة أور من أبرز آثار المدينة القديمة.'),
 _Question('ما عاصمة الدولة العباسية في أوجها؟',['دمشق','بغداد','القاهرة','سامراء'],1,'كانت بغداد مركز الخلافة العباسية.'),
 _Question('أي خط استُخدم في الكتابة القديمة على ألواح الطين؟',['النسخي','المسماري','الديواني','الثلث'],1,'الكتابة المسمارية سجلت على ألواح طينية.'),
 _Question('في أي محافظة تقع مدينة بابل الأثرية؟',['نينوى','بابل','الأنبار','ميسان'],1,'تقع آثار بابل في محافظة بابل.')
];
const _geography=[
 _Question('ما أكبر قارة من حيث المساحة؟',['أفريقيا','آسيا','أوروبا','أستراليا'],1,'آسيا أكبر القارات مساحة.'),
 _Question('ما عاصمة اليابان؟',['سيول','طوكيو','بكين','بانكوك'],1,'طوكيو عاصمة اليابان.'),
 _Question('أي نهر يمر في مصر؟',['الأمازون','النيل','الدانوب','الراين'],1,'نهر النيل يمر في مصر.'),
 _Question('ما أعلى سلسلة جبلية في العالم؟',['الألب','الأنديز','الهيمالايا','الأطلس'],2,'تضم الهيمالايا أعلى قمم العالم.'),
 _Question('أي محيط يقع شرق أفريقيا؟',['الأطلسي','الهندي','الهادئ','المتجمد الشمالي'],1,'المحيط الهندي يقع شرق أفريقيا.'),
 _Question('ما عاصمة أستراليا؟',['سيدني','ملبورن','كانبيرا','بيرث'],2,'كانبيرا هي العاصمة.')
];
const _technology=[
 _Question('ماذا تعني CPU؟',['وحدة المعالجة المركزية','ذاكرة التخزين','بطاقة الرسوميات','مزود الطاقة'],0,'CPU هي وحدة المعالجة المركزية.'),
 _Question('ما وظيفة المصادقة الثنائية؟',['تسريع الإنترنت','إضافة طبقة تحقق','زيادة سعة التخزين','ضغط الصور'],1,'تضيف طبقة تحقق ثانية للحساب.'),
 _Question('أي لغة تُستخدم أساساً لتنسيق صفحات الويب؟',['HTML','CSS','SQL','Bash'],1,'CSS مسؤولة عن تنسيق مظهر الصفحات.'),
 _Question('ما المقصود بالنسخ الاحتياطي؟',['حذف الملفات','إنشاء نسخة لاستعادتها','تشفير الشاشة','تحديث المتصفح'],1,'النسخة الاحتياطية تساعد على استعادة البيانات.'),
 _Question('ما وظيفة نظام GPS؟',['قياس الصوت','تحديد الموقع','ضغط الملفات','تعديل الصور'],1,'GPS يساعد على تحديد الموقع الجغرافي.'),
 _Question('أي كلمة مرور أقوى عادة؟',['12345678','اسمك فقط','عبارة طويلة وفريدة','تاريخ ميلادك'],2,'العبارة الطويلة والفريدة أكثر أماناً.')
];
const _animals=[
 _Question('ما أكبر حيوان معروف على الأرض؟',['الفيل الأفريقي','الحوت الأزرق','الزرافة','وحيد القرن'],1,'الحوت الأزرق أكبر الحيوانات المعروفة.'),
 _Question('أي حيوان يُعرف بسفينة الصحراء؟',['الجمل','الحصان','اللاما','الغزال'],0,'الجمل متكيف مع البيئات الصحراوية.'),
 _Question('ما الثديي الذي يستطيع الطيران الحقيقي؟',['السنجاب','الخفاش','البطريق','النعامة'],1,'الخفافيش هي الثدييات القادرة على الطيران.'),
 _Question('ماذا يسمى صغير الضفدع؟',['يرقة','شرغوف','جرو','فرخ'],1,'يسمى صغير الضفدع شرغوفاً.'),
 _Question('أي طائر لا يستطيع الطيران ويعيش في القطب الجنوبي؟',['النسر','البطريق','الصقر','اللقلق'],1,'البطريق طائر لا يطير.'),
 _Question('كم عدد أرجل العنكبوت؟',['6','8','10','12'],1,'للعنكبوت ثماني أرجل.')
];
const _space=[
 _Question('ما الكوكب المعروف بالكوكب الأحمر؟',['المريخ','المشتري','الزهرة','نبتون'],0,'المريخ يبدو أحمر بسبب أكاسيد الحديد.'),
 _Question('ما اسم مجرتنا؟',['أندروميدا','درب التبانة','السحابة الكبرى','العين السوداء'],1,'مجموعتنا الشمسية ضمن درب التبانة.'),
 _Question('أي كوكب هو الأكبر في المجموعة الشمسية؟',['زحل','الأرض','المشتري','أورانوس'],2,'المشتري أكبر كواكب المجموعة الشمسية.'),
 _Question('ما النجم الأقرب إلى الأرض؟',['الشعرى','الشمس','النسر الواقع','سهيل'],1,'الشمس أقرب النجوم إلى الأرض.'),
 _Question('ما اسم القمر الطبيعي للأرض؟',['فوبوس','تيتان','القمر','أوروبا'],2,'القمر هو التابع الطبيعي للأرض.'),
 _Question('لماذا نرى النجوم تلمع؟',['لأنها مصابيح','بسبب اضطراب الغلاف الجوي','لأنها قريبة جداً','لأنها تعكس القمر فقط'],1,'اضطراب الغلاف الجوي يغير مسار الضوء الواصل إلينا.')
];
const _football=[
 _Question('كم لاعباً يبدأ به الفريق مباراة كرة القدم داخل الملعب؟',['9','10','11','12'],2,'الفريق يبدأ بأحد عشر لاعباً.'),
 _Question('كم مدة المباراة الأصلية؟',['60','80','90','100'],2,'تسعون دقيقة على شوطين.'),
 _Question('أي منتخب فاز بكأس العالم 2022؟',['فرنسا','الأرجنتين','البرازيل','كرواتيا'],1,'الأرجنتين توجت بلقب 2022.'),
 _Question('أي نادٍ يُلقب بالملكي؟',['برشلونة','ريال مدريد','ليفربول','ميلان'],1,'ريال مدريد يُعرف بالملكي.'),
 _Question('كم لاعباً من كل فريق يكون داخل الملعب عند بداية المباراة؟',['10','11','12','9'],1,'أحد عشر لاعباً.'),
 _Question('ما اسم البطولة الأوروبية للأندية الأبطال؟',['الدوري الأوروبي','دوري أبطال أوروبا','كأس العالم','كأس القارات'],1,'دوري أبطال أوروبا.'),
 _Question('أي منتخب يُلقب بالسامبا؟',['الأرجنتين','البرازيل','أوروغواي','تشيلي'],1,'البرازيل تُعرف بمنتخب السامبا.'),
 _Question('ما لون البطاقة التي تعني الطرد؟',['الصفراء','الحمراء','الزرقاء','الخضراء'],1,'البطاقة الحمراء تعني الطرد.'),
 _Question('أي مركز يرتدي غالباً القفازات؟',['المهاجم','المدافع','حارس المرمى','الجناح'],2,'حارس المرمى يرتدي القفازات عادة.'),
 _Question('كم نقطة للفوز في الدوري؟',['1','2','3','4'],2,'الفوز بثلاث نقاط.'),
 _Question('أي نادٍ ملعبه أنفيلد؟',['مانشستر سيتي','ليفربول','تشيلسي','أرسنال'],1,'أنفيلد ملعب ليفربول.'),
 _Question('أي منتخب فاز بكأس العالم 2018؟',['ألمانيا','فرنسا','كرواتيا','إسبانيا'],1,'فرنسا فازت في 2018.'),
 _Question('ما اسم ركلة استئناف اللعب من الزاوية؟',['ركلة حرة','ركلة مرمى','ركلة ركنية','ركلة جزاء'],2,'الركلة الركنية من زاوية الملعب.'),
 _Question('أي نادٍ إيطالي ألوانه الأحمر والأسود؟',['يوفنتوس','ميلان','إنتر','روما'],1,'إيه سي ميلان ألوانه الأحمر والأسود.'),
 _Question('كم حكماً مساعداً يكون عادة على خطي التماس؟',['1','2','3','4'],1,'حكمان مساعدان على الخطين.'),
];
const _players=[
 _Question('لاعب أرجنتيني فاز بكأس العالم 2022 ويلعب غالباً صانع ألعاب أو مهاجماً؟',['ليونيل ميسي','أنخيل دي ماريا','باولو ديبالا','لاوتارو مارتينيز'],0,'هو ليونيل ميسي.'),
 _Question('لاعب برتغالي اشتهر بالرقم 7 ولعب لمانشستر يونايتد وريال مدريد؟',['برونو فيرنانديز','كريستيانو رونالدو','ناني','بيرناردو سيلفا'],1,'هو كريستيانو رونالدو.'),
 _Question('لاعب مصري يُلقب بالملك المصري ويلعب جناحاً؟',['محمد صلاح','عمر مرموش','محمد النني','مصطفى محمد'],0,'هو محمد صلاح.'),
 _Question('لاعب فرنسي سريع فاز بكأس العالم 2018؟',['غريزمان','مبابي','كانتي','جيرود'],1,'هو كيليان مبابي.'),
 _Question('لاعب برازيلي اشتهر بالمهارات واللعب مع برشلونة وباريس؟',['رونالدو','كاكا','نيمار','ريفالدو'],2,'هو نيمار.'),
 _Question('حارس إسباني مشهور لعب لمانشستر يونايتد؟',['كاسياس','دي خيا','فالديس','رايا'],1,'هو دافيد دي خيا.'),
 _Question('لاعب نرويجي مهاجم هداف في مانشستر سيتي؟',['أوديغارد','هالاند','سورلوث','راشفورد'],1,'هو إيرلينغ هالاند.'),
 _Question('لاعب كرواتي فاز بالكرة الذهبية عام 2018؟',['مودريتش','راكيتيتش','ماندزوكيتش','بيريسيتش'],0,'هو لوكا مودريتش.'),
 _Question('لاعب بلجيكي صانع ألعاب لعب لمانشستر سيتي؟',['هازارد','دي بروين','لوكاكو','كورتوا'],1,'هو كيفن دي بروين.'),
 _Question('أسطورة أرجنتينية ارتبط اسمها بيد الله وكأس العالم 1986؟',['باتيستوتا','مارادونا','ريكيلمي','أغويرو'],1,'هو دييغو مارادونا.'),
];
const _flags=[
 _Question('🇮🇶 لأي دولة هذا العلم؟',['العراق','سوريا','الأردن','الكويت'],0,'هذا علم العراق.'),
 _Question('🇯🇵 أي دولة تستخدم هذا العلم؟',['الصين','اليابان','كوريا الجنوبية','تايلند'],1,'هذا علم اليابان.'),
 _Question('🇧🇷 هذا علم أي دولة؟',['البرتغال','الأرجنتين','البرازيل','المكسيك'],2,'هذا علم البرازيل.'),
 _Question('🇫🇷 لأي دولة ينتمي العلم؟',['إيطاليا','فرنسا','هولندا','بلجيكا'],1,'هذا علم فرنسا.'),
 _Question('🇩🇪 هذا علم أي دولة؟',['ألمانيا','النمسا','سويسرا','بولندا'],0,'هذا علم ألمانيا.'),
 _Question('🇸🇦 أي دولة علمها أخضر وفيه الشهادتان؟',['الإمارات','قطر','السعودية','عُمان'],2,'هذا علم المملكة العربية السعودية.'),
 _Question('🇪🇬 علم أي دولة؟',['مصر','اليمن','العراق','السودان'],0,'هذا علم مصر.'),
 _Question('🇦🇷 هذا علم أي دولة؟',['الأوروغواي','الأرجنتين','تشيلي','باراغواي'],1,'هذا علم الأرجنتين.'),
 _Question('🇨🇦 أي دولة يظهر ورق القيقب على علمها؟',['أستراليا','كندا','نيوزيلندا','أمريكا'],1,'هذا علم كندا.'),
 _Question('🇮🇹 أي دولة علمها أخضر وأبيض وأحمر عمودياً؟',['إيرلندا','المكسيك','إيطاليا','بلغاريا'],2,'هذا علم إيطاليا.'),
];
const _anime=[
 _Question('من هو بطل أنمي Naruto؟',['ساسكي','ناروتو','كاكاشي','غاارا'],1,'ناروتو أوزوماكي هو البطل.'),
 _Question('ما اسم طاقم لوفي؟',['قبعة القش','اللحية البيضاء','القراصنة الحمر','القبعة السوداء'],0,'طاقم قبعة القش.'),
 _Question('من يستخدم دفتر الموت؟',['إدوارد','لايت ياغامي','تانجيرو','غون'],1,'لايت ياغامي هو حامل الدفتر.'),
 _Question('ما اسم أخت تانجيرو؟',['ساكورا','نيزوكو','هيناتا','نوبارا'],1,'نيزوكو كامادو.'),
 _Question('من هو سايان ابن غوكو؟',['فيجيتا','غوهان','بيكولو','ترانكس'],1,'غوهان ابن غوكو.'),
 _Question('في One Piece، ما حلم زورو؟',['أن يصبح ملك القراصنة','أن يصبح أفضل سياف','أن يجد كنزاً','أن يصبح طبيباً'],1,'زورو يريد أن يصبح أفضل سياف في العالم.'),
 _Question('ما اسم بطل Attack on Titan؟',['إيرين','ليفاي','أرمين','إروين'],0,'إيرين ييغر.'),
 _Question('أي شخصية ترتدي قناعاً برتقالياً في Tokyo Ghoul؟',['كانيكي','توكا','هيدي','أمون'],0,'كانيكي كين.'),
 _Question('ما اسم مدرسة الأبطال في My Hero Academia؟',['كيوتو','UA','هوغوورتس','طوكيو هاي'],1,'مدرسة UA.'),
 _Question('من بطل Jujutsu Kaisen؟',['يوجي إيتادوري','غوجو','ميغومي','سوكونا'],0,'يوجي إيتادوري هو البطل الرئيسي.'),
];
const _clubs=[
 _Question('أي نادٍ يُلقب بالشياطين الحمر؟',['ليفربول','مانشستر يونايتد','أرسنال','تشيلسي'],1,'مانشستر يونايتد يُلقب بالشياطين الحمر.'),
 _Question('من هو النادي المعروف بالبلوغرانا؟',['ريال مدريد','برشلونة','إشبيلية','فالنسيا'],1,'برشلونة يُعرف بالبلوغرانا.'),
 _Question('أي نادٍ إيطالي يُلقب بالسيدة العجوز؟',['ميلان','إنتر','يوفنتوس','نابولي'],2,'يوفنتوس هو السيدة العجوز.'),
 _Question('أي نادٍ ملعبه أنفيلد؟',['ليفربول','مانشستر سيتي','أرسنال','توتنهام'],0,'أنفيلد ملعب ليفربول.'),
 _Question('أي نادٍ ألماني يلعب في أليانز أرينا؟',['دورتموند','بايرن ميونخ','لايبزيغ','ليفركوزن'],1,'بايرن ميونخ يلعب في أليانز أرينا.'),
 _Question('أي نادٍ فرنسي يُعرف بلقب باريس؟',['ليون','موناكو','باريس سان جيرمان','ليل'],2,'باريس سان جيرمان.'),
 _Question('أي نادٍ إسباني ملعبه سانتياغو برنابيو؟',['أتلتيكو','ريال مدريد','برشلونة','إشبيلية'],1,'ريال مدريد.'),
 _Question('أي نادٍ إنجليزي يُلقب بالمدفعجية؟',['تشيلسي','أرسنال','إيفرتون','وست هام'],1,'أرسنال يُلقب بالمدفعجية.'),
];

class _QuizGame extends StatefulWidget {
  final String category;
  const _QuizGame({required this.category});
  @override
  State<_QuizGame> createState() => _QuizGameState();
}

class _QuizGameState extends State<_QuizGame> {
  late List<_Question> qs;
  int index = 0;
  int score = 0;
  int? picked;
  bool finished = false;

  @override
  void initState() {
    super.initState();
    final source = switch (widget.category) {
      'football' => _football,
      'player' => _players,
      'flags' => _flags,
      'anime' => _anime,
      'clubs' => _clubs,
      'science' => _science,
      'iraq' => _iraq,
      'geography' => _geography,
      'technology' => _technology,
      'animals' => _animals,
      'space' => _space,
      _ => _general,
    };
    qs = List<_Question>.from(source)..shuffle(Random());
    if (widget.category == 'speed') qs = qs.take(10).toList();
  }

  void choose(int i) {
    if (picked != null) return;
    setState(() => picked = i);
  }

  void next() {
    if (picked == qs[index].correct) score++;
    if (index == qs.length - 1) {
      setState(() => finished = true);
    } else {
      setState(() {
        index++;
        picked = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = qs[index];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(switch (widget.category) {
            'football' => 'تحدي كرة القدم',
            'player' => 'من هو اللاعب؟',
            'flags' => 'تحدي الأعلام',
            'anime' => 'تحدي الأنمي',
            'clubs' => 'شعارات الأندية',
            'science' => 'تحدي العلوم',
            'iraq' => 'ذاكرة العراق',
            'geography' => 'رحلة حول العالم',
            'technology' => 'تحدي التقنية',
            'animals' => 'مملكة الحيوانات',
            'space' => 'أسرار الفضاء',
            _ => 'تحدي المعلومات',
          }),
        ),
        body: Padding(
          padding: const EdgeInsets.all(18),
          child: finished
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events, size: 70, color: Colors.amber),
                      Text('نتيجتك: $score من ${qs.length}',
                          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                      FilledButton(
                        onPressed: () => setState(() {
                          index = 0;
                          score = 0;
                          picked = null;
                          finished = false;
                          qs.shuffle(Random());
                        }),
                        child: const Text('العب مرة ثانية'),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(value: (index + 1) / qs.length),
                    const SizedBox(height: 18),
                    Text('السؤال ${index + 1} من ${qs.length}',
                        style: const TextStyle(color: gameViolet, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(q.q, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 18),
                    ...List.generate(q.a.length, (i) {
                      final answered = picked != null;
                      final correct = answered && i == q.correct;
                      final selectedWrong = answered && picked == i && i != q.correct;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: correct
                                ? Colors.green.withValues(alpha: .12)
                                : selectedWrong
                                    ? Colors.red.withValues(alpha: .1)
                                    : null,
                            padding: const EdgeInsets.all(15),
                          ),
                          onPressed: answered ? null : () => choose(i),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(q.a[i]),
                          ),
                        ),
                      );
                    }),
                    if (picked != null) ...[
                      Text(picked == q.correct
                          ? 'إجابة صحيحة!'
                          : 'الإجابة الصحيحة: ${q.a[q.correct]}'),
                      Text(q.why),
                      const Spacer(),
                      FilledButton(
                        onPressed: next,
                        child: Text(index == qs.length - 1 ? 'عرض النتيجة' : 'السؤال التالي'),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
class GameInvitesPage extends StatefulWidget{const GameInvitesPage({super.key});@override State<GameInvitesPage> createState()=>_GameInvitesPageState();}
class _GameInvitesPageState extends State<GameInvitesPage>{
 Future<void> invite()async{
  final users=await gameDb.collection('publicProfiles').limit(80).get();if(!mounted)return;
  final candidates=users.docs.where((d)=>d.id!=gameUid).toList();if(candidates.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('ماكو أعضاء متاحين للدعوة حالياً')));return;}
  final chosen=await showModalBottomSheet<String>(context:context,builder:(c)=>SafeArea(child:ListView(children:candidates.map((d)=>ListTile(leading:const CircleAvatar(child:Icon(Icons.person)),title:Text(d.data()['name']??'عضو'),onTap:()=>Navigator.pop(c,d.id))).toList())));
  if(chosen==null)return;
  final me=await gameDb.collection('publicProfiles').doc(gameUid).get();
  await gameDb.collection('gameInvites').add({'from':gameUid,'to':chosen,'fromName':me.data()?['name']??'عضو','game':'general','status':'pending','createdAt':FieldValue.serverTimestamp()});
  if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم إرسال الدعوة')));
 }
 Future<void> answer(String id,bool accept)async=>gameDb.collection('gameInvites').doc(id).update({'status':accept?'accepted':'declined'});
 @override Widget build(BuildContext c)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('دعوات اللعب'),actions:[IconButton(onPressed:invite,icon:const Icon(Icons.person_add_alt_1))]),body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:gameDb.collection('gameInvites').where('to',isEqualTo:gameUid).orderBy('createdAt',descending:true).limit(40).snapshots(),builder:(c,s){if(s.hasError)return const Center(child:Text('تعذر تحميل الدعوات؛ قد تحتاج قواعد Firestore الجديدة.'));if(!s.hasData)return const Center(child:CircularProgressIndicator());if(s.data!.docs.isEmpty)return const Center(child:Text('ما عندك دعوات حالياً. اضغط + لدعوة عضو.'));return ListView(children:s.data!.docs.map((d){final x=d.data();return Card(child:ListTile(title:Text('دعوة من ${x['fromName']??'عضو'}'),subtitle:Text('الحالة: ${x['status']}'),trailing:x['status']=='pending'?Wrap(children:[IconButton(onPressed:()=>answer(d.id,true),icon:const Icon(Icons.check,color:Colors.green)),IconButton(onPressed:()=>answer(d.id,false),icon:const Icon(Icons.close,color:Colors.red))]):null));}).toList());})));
 }

class ArcadeGamesHubScreen extends StatelessWidget {
  const ArcadeGamesHubScreen({super.key});
  static const games = [
    ['ضربات الجزاء','3D رياضة','⚽','penalty'],
    ['سباق النفق','3D سرعة','🚀','tunnel'],
    ['صياد النجوم','3D فضاء','🌌','stars'],
    ['صائد القلوب','2D مهارة','💗','hearts'],
    ['معركة النقر','2D لاعبان','⚡','tap'],
    ['رد الفعل','2D لاعبان','⏱️','reaction'],
    ['كاسر الشفرة','2D ذكاء','🔐','code'],
    ['الثعبان النيون','2D كلاسيك','🐍','snake'],
    ['2048 السريع','2D أرقام','🔢','2048'],
    ['قنّاص الهدف','2D دقة','🎯','target'],
  ];
  @override Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: const Color(0xFF0C1020),
      appBar: AppBar(title: const Text('صالة ألعاب 2D + 3D'), backgroundColor: const Color(0xFF151B31), foregroundColor: Colors.white),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [Color(0xFF352B78), Color(0xFF126D79)])),
            child: const Text('صالة ألعاب الملتقى 🎮\n10 ألعاب خفيفة وفورية، منها تحديات لشخصين على نفس الجهاز.', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold, height: 1.6)),
          ),
        )),
        SliverPadding(padding: const EdgeInsets.all(14), sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate((context, i) {
            final g = games[i];
            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArcadeHubGamePage(title: g[0], mode: g[3]))),
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFF171D32), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white24)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(g[2], style: const TextStyle(fontSize: 38)),
                  const SizedBox(height: 8),
                  Text(g[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(g[1], style: const TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                  const SizedBox(height: 8),
                  const Text('العب الآن ←', style: TextStyle(color: Colors.white54, fontSize: 11)),
                ]),
              ),
            );
          }, childCount: games.length),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .95),
        )),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FutureArcadePage())),
            icon: const Icon(Icons.groups_rounded),
            label: const Text('غرف الأصدقاء والدردشة والفويس'),
          ),
        )),
      ]),
    ),
  );
}

class ArcadeHubGamePage extends StatefulWidget {
  final String title, mode;
  const ArcadeHubGamePage({super.key, required this.title, required this.mode});
  @override State<ArcadeHubGamePage> createState() => _ArcadeHubGamePageState();
}

class _ArcadeHubGamePageState extends State<ArcadeHubGamePage> {
  final random = Random();
  final guess = TextEditingController();
  int score = 0, secret = 0, taps = 0, snake = 20;
  bool started = false, green = false, ended = false;
  String note = 'اضغط ابدأ للعب';
  @override void initState() { super.initState(); secret = 1000 + random.nextInt(8999); }
  @override void dispose() { guess.dispose(); super.dispose(); }
  void reset() => setState(() { score = 0; taps = 0; started = false; green = false; ended = false; secret = 1000 + random.nextInt(8999); note = 'اضغط ابدأ للعب'; });
  void begin() {
    setState(() { started = true; note = 'يلا نبدأ!'; });
    if (widget.mode == 'reaction') {
      Future.delayed(Duration(milliseconds: 1400 + random.nextInt(2500)), () {
        if (mounted && !ended) setState(() { green = true; note = 'اضغط الآن!'; });
      });
    }
  }
  void hit() {
    if (!started) { begin(); return; }
    if (ended) return;
    setState(() {
      score++;
      note = widget.mode == 'penalty' ? 'هدف! ⚽' : widget.mode == 'hearts' ? 'جمعت قلب! 💗' : 'إصابة ممتازة!';
    });
  }
  Widget action(String text, VoidCallback fn) => FilledButton(onPressed: fn, child: Text(text));
  @override Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: const Color(0xFF0C1020),
      appBar: AppBar(title: Text(widget.title), backgroundColor: const Color(0xFF151B31), foregroundColor: Colors.white),
      body: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        Text('النقاط: ' + score.toString(), style: const TextStyle(color: Colors.cyanAccent, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        Expanded(child: Container(
          width: double.infinity,
          decoration: BoxDecoration(color: const Color(0xFF171D32), borderRadius: BorderRadius.circular(22)),
          child: _board(),
        )),
        const SizedBox(height: 12),
        Text(note, style: const TextStyle(color: Colors.cyanAccent, fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (ended) action('إعادة اللعب', reset)
        else if (!started) action('ابدأ اللعب', begin)
        else if (widget.mode == 'tap') Row(children: [
          Expanded(child: action('فاطمة 💗', () { setState(() { taps++; if (taps >= 10) { ended = true; note = 'فازت فاطمة!'; } }) ;})),
          const SizedBox(width: 8),
          Expanded(child: action('حسون ⚡', () { setState(() { taps--; if (taps <= -10) { ended = true; note = 'فاز حسون!'; } }) ;})),
        ])
        else if (widget.mode == 'reaction') Row(children: [
          Expanded(child: action('فاطمة', () => _react('فاطمة'))),
          const SizedBox(width: 8),
          Expanded(child: action('حسون', () => _react('حسون'))),
        ])
        else if (widget.mode == 'code') _codeControls()
        else action('جولة جديدة', reset),
      ])),
    ));
  }
  void _react(String who) {
    if (!green) { setState(() { ended = true; note = 'تسرّع ' + who + '!'; }); }
    else { setState(() { ended = true; note = 'فاز ' + who + ' برد الفعل! 🏆'; }); }
  }
  Widget _codeControls() => Row(children: [
    Expanded(child: TextField(controller: guess, keyboardType: TextInputType.number, maxLength: 4, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(counterText: '', hintText: 'أربعة أرقام'))),
    action('تحقق', () {
      final n = int.tryParse(guess.text);
      if (n == null) { setState(() => note = 'أدخل أربعة أرقام'); return; }
      setState(() => note = n == secret ? 'كسرت الشفرة! 🎉' : n < secret ? 'الشفرة أكبر ↑' : 'الشفرة أصغر ↓');
      if (n == secret) setState(() => ended = true);
      guess.clear();
    }),
  ]);
  Widget _board() {
    if (widget.mode == 'tap') return const Center(child: Text('كل لاعب يضغط على زره بالأسفل\\nأول من يصل 10 نقاط يفوز', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 20)));
    if (widget.mode == 'reaction') return GestureDetector(onTap: () => _react('اللاعب'), child: Container(color: green ? Colors.green : Colors.red.shade900, alignment: Alignment.center, child: Text(green ? 'اضغط الآن!' : 'انتظر اللون الأخضر', style: const TextStyle(color: Colors.white, fontSize: 24))));
    if (widget.mode == 'code') return const Center(child: Text('خمّن الرقم السري من 4 خانات', style: TextStyle(color: Colors.white, fontSize: 20)));
    if (widget.mode == 'snake') return Center(child: Text('🐍\\n' + '■ ' * (score + 3), style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 26)));
    if (widget.mode == '2048') return GestureDetector(onHorizontalDragEnd: (_) => setState(() => score += 2), child: Center(child: Text('2048\\n' + score.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold))));
    return GestureDetector(onTap: hit, onHorizontalDragEnd: (_) => hit(), child: Stack(children: [
      Positioned.fill(child: CustomPaint(painter: _ArcadeHubPainter(widget.mode))),
      Center(child: Text(widget.mode == 'hearts' ? '💗' : widget.mode == 'penalty' ? '⚽' : widget.mode == 'tunnel' ? '🚧' : '✦', style: const TextStyle(fontSize: 65))),
      const Align(alignment: Alignment.bottomCenter, child: Padding(padding: EdgeInsets.all(14), child: Text('المس الشاشة أو اسحب للتحدي', style: TextStyle(color: Colors.white70)))),
    ]));
  }
}

class _ArcadeHubPainter extends CustomPainter {
  final String mode;
  _ArcadeHubPainter(this.mode);
  @override void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.cyanAccent.withOpacity(.22)..style = PaintingStyle.stroke..strokeWidth = 2;
    for (int i = 1; i < 7; i++) {
      final inset = i * size.width / 16;
      canvas.drawRect(Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2), p);
    }
    if (mode == 'penalty') canvas.drawRect(Rect.fromLTWH(size.width * .2, size.height * .18, size.width * .6, size.height * .3), Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 4);
    if (mode == 'stars') for (int i = 0; i < 35; i++) canvas.drawCircle(Offset((i * 73 % 997) / 997 * size.width, (i * 131 % 991) / 991 * size.height), 1.5, Paint()..color = Colors.white70);
  }
  @override bool shouldRepaint(covariant _ArcadeHubPainter oldDelegate) => oldDelegate.mode != mode;
}
