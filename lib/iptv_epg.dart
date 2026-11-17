import 'package:xml/xml.dart';

class IptvProgram {
  const IptvProgram({required this.channelId,required this.title,required this.start,required this.stop,this.description=''});
  final String channelId,title,description;
  final DateTime start,stop;
  bool isOn(DateTime now)=>!now.isBefore(start)&&now.isBefore(stop);
  Map<String,dynamic> toJson()=>{'channelId':channelId,'title':title,'description':description,'start':start.toIso8601String(),'stop':stop.toIso8601String()};
  factory IptvProgram.fromJson(Map<String,dynamic> j)=>IptvProgram(channelId:j['channelId']?.toString()??'',title:j['title']?.toString()??'',description:j['description']?.toString()??'',start:DateTime.parse(j['start'].toString()),stop:DateTime.parse(j['stop'].toString()));
}

class IptvEpgParser {
  static DateTime? _date(String raw) {
    final m=RegExp(r'^(\\d{4})(\\d{2})(\\d{2})(\\d{2})(\\d{2})(\\d{2})(?:\\s*([+-])(\\d{2})(\\d{2}))?$').firstMatch(raw.trim());
    if(m==null)return null;
    try {
      final local=DateTime.utc(int.parse(m[1]!),int.parse(m[2]!),int.parse(m[3]!),int.parse(m[4]!),int.parse(m[5]!),int.parse(m[6]!));
      if(m[7]==null)return local;
      final offset=(int.parse(m[8]!)*60+int.parse(m[9]!))*(m[7]=='+'?1:-1);
      return local.subtract(Duration(minutes:offset));
    } catch(_){return null;}
  }
  static List<IptvProgram> parse(String xml) {
    final out=<IptvProgram>[];
    try {
      final doc=XmlDocument.parse(xml);
      for(final node in doc.findAllElements('programme')) {
        final id=node.getAttribute('channel')?.trim()??'';
        final start=_date(node.getAttribute('start')??'');
        final stop=_date(node.getAttribute('stop')??'');
        final title=node.getElement('title')?.innerText.trim()??'';
        final desc=node.getElement('desc')?.innerText.trim()??'';
        if(id.isEmpty||start==null||stop==null||!stop.isAfter(start)||title.isEmpty)continue;
        out.add(IptvProgram(channelId:id,title:title,start:start,stop:stop,description:desc));
      }
    } catch(_){return const [];}
    out.sort((a,b)=>a.start.compareTo(b.start));
    return out;
  }
  static IptvProgram? current(List<IptvProgram> items,String channelId,DateTime now) {
    for(final p in items){if(p.channelId==channelId&&p.isOn(now))return p;}
    return null;
  }
  static IptvProgram? next(List<IptvProgram> items,String channelId,DateTime now) {
    for(final p in items){if(p.channelId==channelId&&p.start.isAfter(now))return p;}
    return null;
  }
}
