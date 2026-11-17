import 'package:flutter_test/flutter_test.dart';
import 'package:future_youth_forum/iptv_epg.dart';

void main(){
  test('parses XMLTV programmes and UTC offsets',(){
    const xml='<tv><programme channel="news" start="20261117180000 +0300" stop="20261117190000 +0300"><title>Evening News</title><desc>Daily bulletin</desc></programme></tv>';
    final items=IptvEpgParser.parse(xml);
    expect(items,hasLength(1));
    expect(items.first.title,'Evening News');
    expect(items.first.start,DateTime.utc(2026,11,17,15));
    expect(items.first.description,'Daily bulletin');
  });
  test('ignores invalid or incomplete programme entries',(){
    const xml='<tv><programme channel="x" start="bad" stop="bad"><title>Broken</title></programme><programme start="20261117180000 +0000" stop="20261117190000 +0000"><title>No channel</title></programme></tv>';
    expect(IptvEpgParser.parse(xml),isEmpty);
  });
  test('finds current and next programme for a channel',(){
    final now=DateTime.utc(2026,11,17,15,30);
    final items=IptvEpgParser.parse('<tv><programme channel="news" start="20261117150000 +0000" stop="20261117160000 +0000"><title>Now</title></programme><programme channel="news" start="20261117160000 +0000" stop="20261117170000 +0000"><title>Next</title></programme></tv>');
    expect(IptvEpgParser.current(items,'news',now)?.title,'Now');
    expect(IptvEpgParser.next(items,'news',now)?.title,'Next');
  });
}
