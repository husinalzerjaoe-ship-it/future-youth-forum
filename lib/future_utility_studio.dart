import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline-first tools with local-only notes and calculations.
class FutureUtilityStudioPage extends StatefulWidget {
  const FutureUtilityStudioPage({super.key});
  @override
  State<FutureUtilityStudioPage> createState() => _FutureUtilityStudioPageState();
}

class _FutureUtilityStudioPageState extends State<FutureUtilityStudioPage> {
  final _random = Random();
  final _note = TextEditingController();
  String _savedNote = '';
  bool _loading = true;

  static const _tools = <({String title, String subtitle, IconData icon, String group})>[
    (title:'آلة حاسبة',subtitle:'جمع وطرح وضرب وقسمة',icon:Icons.calculate_rounded,group:'الحساب'),
    (title:'حاسبة النسبة',subtitle:'احسب نسبة من قيمة',icon:Icons.percent_rounded,group:'الحساب'),
    (title:'تحويل الوحدات',subtitle:'طول ووزن ووقت وحرارة',icon:Icons.swap_horiz_rounded,group:'الحساب'),
    (title:'حساب العمر',subtitle:'سنوات وأشهر وأيام',icon:Icons.cake_rounded,group:'الوقت'),
    (title:'الفرق بين تاريخين',subtitle:'عدد الأيام بين تاريخين',icon:Icons.date_range_rounded,group:'الوقت'),
    (title:'مولّد الأرقام',subtitle:'رقم عشوائي ضمن مجال',icon:Icons.numbers_rounded,group:'العشوائيات'),
    (title:'رمي النرد',subtitle:'نتيجة من 1 إلى 6',icon:Icons.casino_rounded,group:'العشوائيات'),
    (title:'قرعة الأسماء',subtitle:'اختيار اسم من قائمة',icon:Icons.how_to_vote_rounded,group:'العشوائيات'),
    (title:'قلب العملة',subtitle:'وجه أو كتابة',icon:Icons.monetization_on_rounded,group:'العشوائيات'),
    (title:'عداد النصوص',subtitle:'الكلمات والحروف والأسطر',icon:Icons.text_fields_rounded,group:'الكتابة'),
    (title:'مفكرة سريعة',subtitle:'حفظ ملاحظة على جهازك',icon:Icons.sticky_note_2_rounded,group:'التنظيم'),
    (title:'حاسبة المعدل',subtitle:'متوسط ثلاث درجات',icon:Icons.school_rounded,group:'الدراسة'),
    (title:'حاسبة الخصم',subtitle:'السعر بعد الخصم وقيمة التوفير',icon:Icons.discount_rounded,group:'الحساب'),
    (title:'تقسيم مبلغ',subtitle:'قسمة مبلغ بالتساوي على أشخاص',icon:Icons.groups_rounded,group:'الحساب'),
    (title:'تحويل وقت الدراسة',subtitle:'حوّل الساعات والدقائق إلى دقائق',icon:Icons.timer_outlined,group:'الدراسة'),
    (title:'ترتيب قائمة',subtitle:'تنظيف وترقيم الأسماء أو المهام',icon:Icons.format_list_numbered,group:'الكتابة'),
  ];

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _savedNote = p.getString('future_utility_note') ?? '';
    _note.text = _savedNote;
    if (mounted) setState(() => _loading = false);
  }
  @override
  void dispose() { _note.dispose(); super.dispose(); }

  void _open(String title) {
    switch (title) {
      case 'آلة حاسبة': _form('آلة حاسبة', ['الرقم الأول','الرقم الثاني'], (v) {
        final a=v[0], b=v[1];
        return 'الجمع: ' + _fmt(a+b) + '\nالطرح: ' + _fmt(a-b) + '\nالضرب: ' + _fmt(a*b) + '\nالقسمة: ' + (b==0?'غير ممكن على صفر':_fmt(a/b));
      }); break;
      case 'حاسبة النسبة': _form('حاسبة النسبة', ['القيمة','النسبة المئوية'], (v) => _fmt(v[1]) + '% من ' + _fmt(v[0]) + ' = ' + _fmt(v[0]*v[1]/100)); break;
      case 'تحويل الوحدات': _converter(); break;
      case 'حساب العمر': _form('حساب العمر', ['سنة الميلاد','الشهر','اليوم'], (v) {
        final y=v[0].toInt(), m=v[1].toInt(), d=v[2].toInt();
        if(m<1||m>12||d<1||d>DateTime(y,m+1,0).day) return 'تاريخ غير صحيح';
        final birth=DateTime(y,m,d), now=DateTime.now();
        if(birth.isAfter(now)||y<1900) return 'تاريخ غير صحيح';
        var years=now.year-y, months=now.month-m, days=now.day-d;
        if(days<0){months--;days+=DateTime(now.year,now.month,0).day;}
        if(months<0){years--;months+=12;}
        return 'العمر: ' + years.toString() + ' سنة و' + months.toString() + ' شهر و' + days.toString() + ' يوم';
      }); break;
      case 'الفرق بين تاريخين': _form('الفرق بين تاريخين', ['السنة الأولى','الشهر الأول','اليوم الأول','السنة الثانية','الشهر الثاني','اليوم الثاني'], (v) {
        final a=DateTime(v[0].toInt(),v[1].toInt(),v[2].toInt()), b=DateTime(v[3].toInt(),v[4].toInt(),v[5].toInt());
        if(v[1]<1||v[1]>12||v[4]<1||v[4]>12||v[2]<1||v[5]<1||v[2]>DateTime(a.year,a.month+1,0).day||v[5]>DateTime(b.year,b.month+1,0).day) return 'تاريخ غير صحيح';
        return 'الفارق: ' + b.difference(a).inDays.abs().toString() + ' يوم';
      }); break;
      case 'مولّد الأرقام': _form('مولّد رقم عشوائي', ['الحد الأدنى','الحد الأعلى'], (v) {
        final min=v[0].toInt(), max=v[1].toInt();
        if(max<min||max-min>1000000000) return 'تحقق من المجال';
        return (min+_random.nextInt(max-min+1)).toString();
      }); break;
      case 'رمي النرد': _result('نتيجة النرد', (_random.nextInt(6)+1).toString(), Icons.casino_rounded); break;
      case 'قلب العملة': _result('نتيجة القرعة', _random.nextBool()?'وجه':'كتابة', Icons.monetization_on_rounded); break;
      case 'قرعة الأسماء': _picker(); break;
      case 'عداد النصوص': _counter(); break;
      case 'مفكرة سريعة': _openNote(); break;
      case 'حاسبة المعدل': _form('حاسبة المعدل', ['الدرجة الأولى','الدرجة الثانية','الدرجة الثالثة'], (v) {
        if (v.any((n) => n < 0 || n > 100)) return 'أدخل درجات بين 0 و100';
        return 'المعدل: ${_fmt((v[0]+v[1]+v[2])/3)} من 100';
      }); break;
      case 'حاسبة الخصم': _form('حاسبة الخصم', ['السعر الأصلي','نسبة الخصم'], (v) {
        if (v[0] < 0 || v[1] < 0 || v[1] > 100) return 'تحقق من السعر ونسبة الخصم (0–100)';
        final saving = v[0]*v[1]/100;
        return 'قيمة التوفير: ${_fmt(saving)}\nالسعر بعد الخصم: ${_fmt(v[0]-saving)}';
      }); break;
      case 'تقسيم مبلغ': _form('تقسيم مبلغ', ['المبلغ الكلي','عدد الأشخاص'], (v) {
        if (v[0] < 0 || v[1] < 1 || v[1] > 10000 || v[1] != v[1].roundToDouble()) return 'أدخل مبلغاً صحيحاً وعدداً صحيحاً للأشخاص';
        return 'حصة كل شخص: ${_fmt(v[0]/v[1])}';
      }); break;
      case 'تحويل وقت الدراسة': _form('تحويل وقت الدراسة', ['عدد الساعات','عدد الدقائق'], (v) {
        if (v[0] < 0 || v[1] < 0 || v[1] >= 60) return 'الدقائق تكون من 0 إلى 59';
        return 'المجموع: ${_fmt(v[0]*60+v[1])} دقيقة';
      }); break;
      case 'ترتيب قائمة': _formatList(); break;
    }
  }

  String _fmt(double n) => n.isFinite ? (n==n.roundToDouble()?n.toInt().toString():n.toStringAsFixed(4)) : 'غير صالح';

  Future<void> _form(String title, List<String> labels, String Function(List<double>) calc) async {
    final fields=List.generate(labels.length,(_)=>TextEditingController());
    String result='';
    await showDialog<void>(context:context,builder:(c)=>StatefulBuilder(builder:(c,refresh)=>AlertDialog(
      title:Text(title),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        for(var i=0;i<labels.length;i++) Padding(padding:const EdgeInsets.only(bottom:9),child:TextField(
          controller:fields[i],keyboardType:const TextInputType.numberWithOptions(decimal:true,signed:true),
          decoration:InputDecoration(labelText:labels[i],border:const OutlineInputBorder()))),
        if(result.isNotEmpty) SelectableText(result,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17)),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('إغلاق')),
        FilledButton(onPressed:(){
          final values=fields.map((f)=>double.tryParse(f.text.trim())).toList();
          if(values.any((x)=>x==null)){refresh(()=>result='أدخل أرقاماً صحيحة بكل الحقول');return;}
          try{refresh(()=>result=calc(values.cast<double>()));}catch(_){refresh(()=>result='تعذر الحساب؛ راجع القيم');}
        },child:const Text('احسب'))],
    )));
    for(final f in fields){f.dispose();}
  }

  void _converter() {
    final input=TextEditingController(); String kind='كيلومتر إلى متر', result='';
    const choices=['كيلومتر إلى متر','متر إلى كيلومتر','كيلوغرام إلى غرام','غرام إلى كيلوغرام','ساعات إلى دقائق','دقائق إلى ثوانٍ','مئوية إلى فهرنهايت','فهرنهايت إلى مئوية'];
    showDialog<void>(context:context,builder:(c)=>StatefulBuilder(builder:(c,refresh)=>AlertDialog(
      title:const Text('تحويل الوحدات'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        DropdownButtonFormField<String>(initialValue:kind,items:choices.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(x)=>refresh(()=>kind=x??kind)),
        const SizedBox(height:10),
        TextField(controller:input,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'القيمة',border:OutlineInputBorder())),
        const SizedBox(height:10),SelectableText(result,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('إغلاق')),FilledButton(onPressed:(){
        final n=double.tryParse(input.text.trim()); if(n==null){refresh(()=>result='أدخل قيمة صحيحة');return;}
        final out=switch(kind){
          'كيلومتر إلى متر'=>n*1000,'متر إلى كيلومتر'=>n/1000,'كيلوغرام إلى غرام'=>n*1000,'غرام إلى كيلوغرام'=>n/1000,
          'ساعات إلى دقائق'=>n*60,'دقائق إلى ثوانٍ'=>n*60,'مئوية إلى فهرنهايت'=>n*9/5+32,'فهرنهايت إلى مئوية'=>(n-32)*5/9,_=>n};
        refresh(()=>result=_fmt(out));
      },child:const Text('حوّل'))],
    ))).then((_)=>input.dispose());
  }

  void _picker() {
    final input=TextEditingController();
    showDialog<void>(context:context,builder:(c)=>AlertDialog(
      title:const Text('قرعة الأسماء'),
      content:TextField(controller:input,minLines:3,maxLines:7,decoration:const InputDecoration(hintText:'اكتب كل اسم بسطر منفصل',border:OutlineInputBorder())),
      actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('إغلاق')),FilledButton(onPressed:(){
        final names=input.text.split('\n').map((x)=>x.trim()).where((x)=>x.isNotEmpty).toList();
        if(names.isNotEmpty)_result('الاسم المختار',names[_random.nextInt(names.length)],Icons.emoji_events_rounded);
      },child:const Text('اختَر'))],
    )).then((_)=>input.dispose());
  }

  void _counter() {
    final input=TextEditingController();
    showDialog<void>(context:context,builder:(c)=>StatefulBuilder(builder:(c,refresh)=>AlertDialog(
      title:const Text('عداد النصوص'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:input,minLines:4,maxLines:8,onChanged:(_)=>refresh((){}),decoration:const InputDecoration(hintText:'اكتب أو الصق النص',border:OutlineInputBorder())),
        const SizedBox(height:12),
        Text('الكلمات: ' + (input.text.trim().isEmpty?'0':input.text.trim().split(RegExp(r'\s+')).length.toString()) +
          '  •  الحروف: ' + input.text.length.toString() + '  •  الأسطر: ' + (input.text.isEmpty?0:input.text.split('\n').length).toString()),
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('إغلاق'))],
    ))).then((_)=>input.dispose());
  }

  Future<void> _openNote() async {
    _note.text=_savedNote;
    await showDialog<void>(context:context,builder:(c)=>AlertDialog(
      title:const Text('مفكرتي السريعة'),
      content:TextField(controller:_note,minLines:4,maxLines:9,maxLength:3000,decoration:const InputDecoration(hintText:'ملاحظة خاصة بهذا الجهاز',border:OutlineInputBorder())),
      actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('إغلاق')),FilledButton(onPressed:()async{
        final p=await SharedPreferences.getInstance(); await p.setString('future_utility_note',_note.text);
        if(!mounted)return; setState(()=>_savedNote=_note.text); if(c.mounted)Navigator.pop(c);
      },child:const Text('حفظ'))],
    ));
  }

  void _formatList() {
    final input=TextEditingController();
    showDialog<void>(context:context,builder:(c)=>StatefulBuilder(builder:(c,refresh)=>AlertDialog(
      title:const Text('ترتيب وتنظيف قائمة'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:input,minLines:4,maxLines:8,onChanged:(_)=>refresh((){}),
          decoration:const InputDecoration(hintText:'اكتب كل عنصر بسطر',border:OutlineInputBorder())),
        const SizedBox(height:8),
        Text('عدد العناصر: ${input.text.split('\n').map((x)=>x.trim()).where((x)=>x.isNotEmpty).length}'),
        if(input.text.trim().isNotEmpty) SizedBox(height:130,child:SingleChildScrollView(child:SelectableText(
          input.text.split('\n').map((x)=>x.trim()).where((x)=>x.isNotEmpty).toList().asMap().entries.map((e)=>'${e.key+1}. ${e.value}').join('\n')))),
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('إغلاق'))],
    ))).then((_)=>input.dispose());
  }

  void _result(String title,String value,IconData icon) {
    showDialog<void>(context:context,builder:(c)=>AlertDialog(title:Text(title),content:Column(mainAxisSize:MainAxisSize.min,children:[
      Icon(icon,size:42,color:Theme.of(context).colorScheme.primary),const SizedBox(height:12),
      SelectableText(value,style:const TextStyle(fontSize:26,fontWeight:FontWeight.bold))]),
      actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('إغلاق'))]));
  }

  @override
  Widget build(BuildContext context) {
    final groups=_tools.map((e)=>e.group).toSet();
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(
      appBar:AppBar(title:const Text('استوديو أدوات المستقبل')),
      body:_loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(14),children:[
        Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),
          gradient:const LinearGradient(colors:[Color(0xFF242052),Color(0xFF6554D9),Color(0xFF1D8292)])),
          child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text('أدواتك بيدك ✨',style:TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.bold)),
            SizedBox(height:6),Text('حسابات ووقت وكتابة وتنظيم. المفكرة تحفظ بياناتها محلياً على جهازك.',style:TextStyle(color:Colors.white70,height:1.5)),
          ])),
        const SizedBox(height:12),
        for(final group in groups)...[
          Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Text(group,style:const TextStyle(fontSize:17,fontWeight:FontWeight.bold))),
          GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
            gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,childAspectRatio:1.5,crossAxisSpacing:10,mainAxisSpacing:10),
            itemCount:_tools.where((e)=>e.group==group).length,
            itemBuilder:(context,index){
              final tool=_tools.where((e)=>e.group==group).elementAt(index);
              return Card(child:InkWell(borderRadius:BorderRadius.circular(14),onTap:()=>_open(tool.title),
                child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[
                  Icon(tool.icon,color:Theme.of(context).colorScheme.primary,size:27),const SizedBox(height:8),
                  Text(tool.title,style:const TextStyle(fontWeight:FontWeight.bold)),
                  Text(tool.subtitle,style:Theme.of(context).textTheme.bodySmall,maxLines:2,overflow:TextOverflow.ellipsis),
                ]))));
            }),
        ],
        if(_savedNote.isNotEmpty) ListTile(leading:const Icon(Icons.note_alt_outlined),title:const Text('ملاحظة محفوظة'),subtitle:Text(_savedNote,maxLines:1,overflow:TextOverflow.ellipsis),onTap:()=>_openNote()),
      ]),
    ));
  }
}
