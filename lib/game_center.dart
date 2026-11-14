import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'multiplayer_arcade.dart';
import 'social_party_games.dart';
import 'board_games.dart';
import 'arcade_minigames.dart';
import 'arcade_penalty.dart';

const gameInk=Color(0xFF171936), gameViolet=Color(0xFF6554D9);
final gameDb=FirebaseFirestore.instance;
String get gameUid=>FirebaseAuth.instance.currentUser!.uid;

class GameCenterPage extends StatelessWidget {
 const GameCenterPage({super.key});
 @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
  appBar:AppBar(title:const Text('مركز الألعاب والتحديات')),
  body:ListView(padding:const EdgeInsets.all(14),children:[
   _GameTile(icon:Icons.public,title:'صالة اللعب أونلاين',subtitle:'إكس أو مباشر • رمز غرفة من 6 أرقام • دعوات الأصدقاء',page:const MultiplayerArcadePage()),
   _GameTile(icon:Icons.groups_rounded,title:'ألعاب السهرة الجماعية',subtitle:'الجاسوس والذئب والرسم والخداع والنرد',page:const SocialPartyGamesPage()),
   _GameTile(icon:Icons.grid_4x4,title:'ألعاب الطاولة',subtitle:'الدومينو والدامة لشخصين',page:const BoardGamesPage()),
   _GameTile(icon:Icons.psychology_alt,title:'ألعاب الذكاء السريعة',subtitle:'الذاكرة وترتيب الحروف والتحديات',page:const ArcadeMiniGamesPage()),
   _GameTile(icon:Icons.sports_soccer,title:'ضربات الجزاء',subtitle:'تحدي التسديد والحارس',page:const PenaltyShootoutPage()),
   Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:const LinearGradient(colors:[gameInk,gameViolet,Color(0xFF16A6A0)]),borderRadius:BorderRadius.circular(20)),child:const Text('تحدّى نفسك وأصدقاءك 🎮\nمعلومات عامة • كرة قدم • تخمين لاعبين',style:TextStyle(color:Colors.white,fontSize:21,fontWeight:FontWeight.bold))),
   const SizedBox(height:12),
   _GameTile(icon:Icons.quiz,title:'تحدي المعلومات',subtitle:'أسئلة متنوعة بمستويات مختلفة',page:const _QuizGame(category:'general')),
   _GameTile(icon:Icons.sports_soccer,title:'تحدي كرة القدم',subtitle:'أندية وبطولات ومنتخبات',page:const _QuizGame(category:'football')),
   _GameTile(icon:Icons.person_search,title:'من هو اللاعب؟',subtitle:'خمن اللاعب من التلميحات',page:const _QuizGame(category:'player')),
   _GameTile(icon:Icons.people_alt,title:'دعوات وتحديات الأصدقاء',subtitle:'أرسل دعوة لعضو وتابع تحدياتك',page:const GameInvitesPage()),
   _GameTile(icon:Icons.bolt,title:'تحدي السرعة',subtitle:'جاوب بأسرع ما يمكن',page:const _QuizGame(category:'speed')),
   _GameTile(icon:Icons.flag_outlined,title:'تحدي الأعلام',subtitle:'خمن الدولة من العلم',page:const _QuizGame(category:'flags')),
   _GameTile(icon:Icons.movie_outlined,title:'تحدي الأنمي',subtitle:'شخصيات وأحداث الأنمي',page:const _QuizGame(category:'anime')),
   _GameTile(icon:Icons.shield_outlined,title:'شعارات الأندية',subtitle:'ألقاب وألوان وأندية عالمية',page:const _QuizGame(category:'clubs')),
  ]),
 ));
}
class _GameTile extends StatelessWidget{
 final IconData icon;final String title,subtitle;final Widget page;
 const _GameTile({required this.icon,required this.title,required this.subtitle,required this.page});
 @override Widget build(BuildContext c)=>Card(child:ListTile(leading:CircleAvatar(backgroundColor:gameViolet.withValues(alpha:.12),child:Icon(icon,color:gameViolet)),title:Text(title,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text(subtitle),trailing:const Icon(Icons.chevron_left),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>page))));
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
    final source = widget.category == 'football'
        ? _football
        : widget.category == 'player'
            ? _players
            : widget.category == 'flags'
                ? _flags
                : widget.category == 'anime'
                    ? _anime
                    : widget.category == 'clubs'
                        ? _clubs
                        : _general;
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
          title: Text(widget.category == 'football'
              ? 'تحدي كرة القدم'
              : widget.category == 'player'
                  ? 'من هو اللاعب؟'
                  : widget.category == 'flags'
                      ? 'تحدي الأعلام'
                      : widget.category == 'anime'
                          ? 'تحدي الأنمي'
                          : widget.category == 'clubs'
                              ? 'شعارات الأندية'
                              : 'تحدي المعلومات'),
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
