import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'future_arcade.dart';

const _bg = Color(0xFF0B1020);
const _panel = Color(0xFF171F35);
const _cyan = Color(0xFF45E2E8);
const _purple = Color(0xFF8B72FF);

class ArcadeGamesHubV2Screen extends StatelessWidget {
  const ArcadeGamesHubV2Screen({super.key});

  static const games = <_ArcadeInfo>[
    _ArcadeInfo('ضربات الجزاء','3D منظور • رياضة','⚽','penalty',true),
    _ArcadeInfo('سباق النفق','3D منظور • سرعة','🚀','tunnel',true),
    _ArcadeInfo('صياد النجوم','3D منظور • فضاء','🌌','stars',true),
    _ArcadeInfo('بينج بونج','3D منظور • مهارة','🏓','pingpong',true),
    _ArcadeInfo('صائد القلوب','2D • سرعة','💗','hearts',false),
    _ArcadeInfo('تحدي الذاكرة','2D • أزواج','🧠','memory',false),
    _ArcadeInfo('معركة النقر','2D • لاعبان','⚡','tap',false),
    _ArcadeInfo('رد الفعل','2D • لاعبان','⏱️','reaction',false),
    _ArcadeInfo('كاسر الشفرة','2D • ألغاز','🔐','code',false),
    _ArcadeInfo('الثعبان النيون','2D • كلاسيك','🐍','snake',false),
    _ArcadeInfo('سباق الحساب','2D • تركيز','🔢','math',false),
    _ArcadeInfo('قنص الهدف','2D • دقة','🎯','target',false),
  ];

  @override
  Widget build(BuildContext context) {
    final perspective = games.where((g) => g.perspective).toList();
    final twoD = games.where((g) => !g.perspective).toList();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(title: const Text('صالة ألعاب 2D + 3D'), backgroundColor: _panel, foregroundColor: Colors.white),
        body: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(19),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(23), gradient: const LinearGradient(colors: [Color(0xFF392B82), Color(0xFF126D79)], begin: Alignment.topRight, end: Alignment.bottomLeft)),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ARCADE HUB', style: TextStyle(color: Colors.white70, letterSpacing: 2, fontWeight: FontWeight.bold)),
                SizedBox(height: 9),
                Text('تحدياتك تبدأ من هنا 🎮', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
                SizedBox(height: 7),
                Text('12 لعبة مصغّرة • نتائج قياسية محفوظة • تحديات ثنائية على نفس الجهاز', style: TextStyle(color: Colors.white70, height: 1.5)),
              ]),
            ),
          )),
          _header('ألعاب 3D بمنظور مرئي', 'رسومات منظور داخل Flutter'),
          _grid(perspective),
          _header('ألعاب 2D', 'مهارة وذكاء وتحديات'),
          _grid(twoD),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('اللعب مع الأصدقاء', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('غرف الأصدقاء الموجودة بالتطبيق تبقى منفصلة وتحتفظ بالدردشة والفويس الحالية. لم نغيّر غرف المشاهدة أو الاتصال.', style: TextStyle(color: Colors.white70, height: 1.5)),
                const SizedBox(height: 10),
                FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FutureArcadePage())), icon: const Icon(Icons.groups_rounded), label: const Text('غرف الأصدقاء والدردشة والفويس')),
              ]),
            ),
          )),
        ]),
      ),
    );
  }

  static Widget _header(String title, String sub) => SliverToBoxAdapter(child: Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ])),
      const Icon(Icons.sports_esports_rounded, color: _cyan),
    ]),
  ));

  static Widget _grid(List<_ArcadeInfo> list) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    sliver: SliverGrid(
      delegate: SliverChildBuilderDelegate((context, i) {
        final g = list[i];
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _ArcadePlayPage(game: g))),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: (g.perspective ? _cyan : _purple).withValues(alpha: .35))),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(g.emoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(height: 7),
              Text(g.title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(g.subtitle, textAlign: TextAlign.center, style: const TextStyle(color: _cyan, fontSize: 10)),
              const SizedBox(height: 7),
              const Text('العب الآن', style: TextStyle(color: Colors.white60, fontSize: 11)),
            ]),
          ),
        );
      }, childCount: list.length),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 11, mainAxisSpacing: 11, childAspectRatio: 1.12),
    ),
  );
}

class _ArcadeInfo {
  final String title, subtitle, emoji, mode;
  final bool perspective;
  const _ArcadeInfo(this.title, this.subtitle, this.emoji, this.mode, this.perspective);
}

class _ArcadePlayPage extends StatefulWidget {
  final _ArcadeInfo game;
  const _ArcadePlayPage({required this.game});
  @override State<_ArcadePlayPage> createState() => _ArcadePlayPageState();
}

class _ArcadePlayPageState extends State<_ArcadePlayPage> {
  final _random = Random();
  final _guess = TextEditingController();
  Timer? _timer;
  Timer? _reactionTimer;
  int _score = 0, _best = 0, _seconds = 30, _secret = 0;
  int _lane = 1, _obstacle = 0, _target = 0, _tapOne = 0, _tapTwo = 0;
  int _a = 0, _b = 0, _food = 36, _direction = 1;
  bool _started = false, _finished = false, _green = false, _ballReady = true;
  String _message = 'اضغط ابدأ حتى نلعب';
  List<int> _snake = [27, 26, 25];
  List<String> _cards = [];
  final Set<int> _opened = {}, _matched = {};

  String get _bestKey => 'arcade_best_' + widget.game.mode;

  @override
  void initState() {
    super.initState();
    _prepare();
    _loadBest();
  }

  Future<void> _loadBest() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => _best = p.getInt(_bestKey) ?? 0);
  }

  void _prepare() {
    _secret = 1000 + _random.nextInt(9000);
    _target = _random.nextInt(3);
    _obstacle = _random.nextInt(3);
    _newMath();
    const icons = ['🍎','🚀','🐼','⚽','🌟','🎸'];
    _cards = [...icons, ...icons]..shuffle(_random);
    _opened.clear();
    _matched.clear();
  }

  void _newMath() {
    _a = 2 + _random.nextInt(18);
    _b = 2 + _random.nextInt(12);
  }

  void _start() {
    _stopTimers();
    setState(() {
      _started = true; _finished = false; _green = false; _score = 0;
      _seconds = 30; _tapOne = 0; _tapTwo = 0; _lane = 1;
      _snake = [27, 26, 25]; _direction = 1; _ballReady = true;
      _message = 'بدأت الجولة!'; _prepare();
    });
    final mode = widget.game.mode;
    if (['hearts','stars','target','math'].contains(mode)) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _finished) return;
        if (_seconds <= 1) { _finish('انتهى الوقت!'); } else {
          setState(() {
            _seconds--;
            if (mode == 'stars' || mode == 'target') _target = _random.nextInt(3);
            if (mode == 'math') _newMath();
          });
        }
      });
    } else if (mode == 'tunnel' || mode == 'snake') {
      _timer = Timer.periodic(Duration(milliseconds: mode == 'snake' ? 420 : 750), (_) => _advance());
    } else if (mode == 'reaction') {
      _reactionTimer = Timer(Duration(milliseconds: 1500 + _random.nextInt(2500)), () {
        if (mounted && !_finished) setState(() { _green = true; _message = 'هسه! اضغط بسرعة'; });
      });
    }
  }

  void _advance() {
    if (!mounted || _finished) return;
    setState(() {
      if (widget.game.mode == 'tunnel') {
        if (_lane == _obstacle) { _finish('اصطدمت بالعائق!'); return; }
        _score++;
        _obstacle = _random.nextInt(3);
        _message = 'تفاديت العائق!';
      } else {
        final head = _snake.first;
        final row = head ~/ 8, col = head % 8;
        var next = -1;
        if (_direction == 0 && row > 0) next = head - 8;
        if (_direction == 1 && col < 7) next = head + 1;
        if (_direction == 2 && row < 7) next = head + 8;
        if (_direction == 3 && col > 0) next = head - 1;
        if (next < 0 || _snake.contains(next)) { _finish('انتهت اللعبة!'); return; }
        _snake.insert(0, next);
        if (next == _food) { _score++; do { _food = _random.nextInt(64); } while (_snake.contains(_food)); }
        else { _snake.removeLast(); }
      }
    });
  }

  void _finish(String msg) {
    if (_finished) return;
    _stopTimers();
    setState(() { _finished = true; _started = false; _message = msg; });
    if (_score > _best) {
      _best = _score;
      SharedPreferences.getInstance().then((p) => p.setInt(_bestKey, _best));
    }
  }

  void _stopTimers() { _timer?.cancel(); _timer = null; _reactionTimer?.cancel(); _reactionTimer = null; }

  void _restart() {
    _stopTimers();
    _guess.clear();
    setState(() { _started = false; _finished = false; _score = 0; _message = 'اضغط ابدأ حتى نلعب'; _prepare(); });
  }

  void _point(String msg) {
    if (!_started || _finished) return;
    setState(() { _score++; _message = msg; });
  }

  void _hit(int lane) {
    if (!_started || _finished) return;
    final mode = widget.game.mode;
    if (mode == 'tunnel') { setState(() => _lane = lane); return; }
    if (mode == 'penalty') {
      if (lane == _target) { _finish('الحارس صدّ الكرة!'); } else { _point('جوووول! ⚽'); setState(() => _target = _random.nextInt(3)); }
    } else if (mode == 'stars' || mode == 'target') {
      if (lane == _target) { _point('إصابة دقيقة!'); setState(() => _target = _random.nextInt(3)); }
      else { setState(() => _message = 'اختار الهدف المضيء'); }
    } else if (mode == 'hearts') { _point('جمعت قلباً 💗'); }
    else if (mode == 'pingpong' && _ballReady) {
      setState(() { _ballReady = false; _score++; _message = 'ردّ الكرة بنجاح!'; });
      Future.delayed(const Duration(milliseconds: 450), () { if (mounted && !_finished) setState(() => _ballReady = true); });
    }
  }

  void _playerTap(int player) {
    if (!_started || _finished) return;
    setState(() { if (player == 0) { _tapOne++; } else { _tapTwo++; } });
    if (_tapOne >= 10 || _tapTwo >= 10) {
      _score = max(_tapOne, _tapTwo);
      _finish(_tapOne >= 10 ? 'فاز اللاعب الأول! 🏆' : 'فاز اللاعب الثاني! 🏆');
    } else {
      setState(() => _message = 'الأول $_tapOne — الثاني $_tapTwo');
    }
  }

  void _react(int player) {
    if (!_started || _finished) return;
    if (!_green) { _finish('ضغط مبكراً! خسر التحدي'); return; }
    _score = 1;
    _finish(player == 0 ? 'فاز اللاعب الأول برد الفعل!' : 'فاز اللاعب الثاني برد الفعل!');
  }

  void _checkCode() {
    final raw = _guess.text;
    final n = int.tryParse(raw);
    if (n == null || raw.length != 4) { setState(() => _message = 'اكتب أربعة أرقام'); return; }
    if (n == _secret) { _score = 1; _finish('كسرت الشفرة! 🎉'); }
    else {
      final g = raw.split(''), s = _secret.toString().split('');
      final exact = List.generate(4, (i) => g[i] == s[i]).where((v) => v).length;
      final present = g.where((digit) => s.contains(digit)).length;
      setState(() => _message = 'أماكن صحيحة: $exact • أرقام موجودة: $present');
    }
    _guess.clear();
  }

  void _openCard(int i) {
    if (!_started || _finished || _matched.contains(i) || _opened.contains(i) || _opened.length == 2) return;
    setState(() => _opened.add(i));
    if (_opened.length == 2) {
      final pair = _opened.toList();
      if (_cards[pair[0]] == _cards[pair[1]]) {
        setState(() { _matched.addAll(pair); _opened.clear(); _score++; _message = 'زوج صحيح!'; });
        if (_matched.length == _cards.length) _finish('أكملت كل الأزواج!');
      } else {
        Future.delayed(const Duration(milliseconds: 650), () { if (mounted && !_finished) setState(() => _opened.clear()); });
      }
    }
  }

  @override
  void dispose() { _stopTimers(); _guess.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(title: Text(widget.game.title), backgroundColor: _panel, foregroundColor: Colors.white, actions: [Center(child: Padding(padding: const EdgeInsetsDirectional.only(end: 14), child: Text('الأفضل: $_best', style: const TextStyle(color: _cyan, fontWeight: FontWeight.bold))))]),
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Row(children: [_stat('النقاط','$_score'), const SizedBox(width: 7), _stat('الوقت','$_seconds ث'), const SizedBox(width: 7), _stat('الأفضل','$_best')]),
          const SizedBox(height: 12),
          Expanded(child: Container(width: double.infinity, padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(20)), child: _board())),
          const SizedBox(height: 10),
          Text(_message, textAlign: TextAlign.center, style: const TextStyle(color: _cyan, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: _started ? _restart : _start,
            icon: Icon(_finished ? Icons.refresh : _started ? Icons.stop : Icons.play_arrow),
            label: Text(_finished ? 'العب مرة ثانية' : _started ? 'إنهاء الجولة' : 'ابدأ اللعب'),
          )),
        ]),
      )),
    ),
  );

  Widget _stat(String label, String value) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 9),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .06), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10))]),
  ));

  Widget _board() {
    if (!_started && !_finished) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(widget.game.emoji, style: const TextStyle(fontSize: 70)),
        const SizedBox(height: 12),
        Text(_instructions, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5)),
      ]));
    }
    switch (widget.game.mode) {
      case 'tap':
        return Row(children: [_playerButton('اللاعب الأول', _tapOne, Colors.pinkAccent, () => _playerTap(0)), const SizedBox(width: 8), _playerButton('اللاعب الثاني', _tapTwo, _cyan, () => _playerTap(1))]);
      case 'reaction':
        return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Expanded(child: Center(child: Text(_green ? '🟢 اضغط!' : '🔴 انتظر اللون الأخضر', style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)))),
          Row(children: [Expanded(child: FilledButton(onPressed: () => _react(0), child: const Text('اللاعب الأول'))), const SizedBox(width: 8), Expanded(child: FilledButton(onPressed: () => _react(1), child: const Text('اللاعب الثاني')))]),
        ]);
      case 'code':
        return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('خمّن الشفرة المكوّنة من أربعة أرقام', style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 18),
          TextField(controller: _guess, keyboardType: TextInputType.number, maxLength: 4, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8), decoration: const InputDecoration(counterText: '', hintText: '0000')),
          FilledButton(onPressed: _checkCode, child: const Text('تحقق')),
        ]);
      case 'memory':
        return GridView.builder(itemCount: _cards.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8), itemBuilder: (c,i) {
          final show = _opened.contains(i) || _matched.contains(i);
          return InkWell(onTap: () => _openCard(i), child: Container(decoration: BoxDecoration(color: show ? _purple.withValues(alpha: .3) : const Color(0xFF263453), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(show ? _cards[i] : '؟', style: const TextStyle(fontSize: 29)))));
        });
      case 'snake':
        return Column(children: [
          Expanded(child: GridView.builder(physics: const NeverScrollableScrollPhysics(), itemCount: 64, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8, crossAxisSpacing: 2, mainAxisSpacing: 2), itemBuilder: (c,i) => Container(decoration: BoxDecoration(color: i == _food ? Colors.pinkAccent : _snake.contains(i) ? _cyan : Colors.white10, borderRadius: BorderRadius.circular(3))))),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(onPressed: () => _direction = 0, icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white)),
            IconButton(onPressed: () => _direction = 3, icon: const Icon(Icons.keyboard_arrow_left, color: Colors.white)),
            IconButton(onPressed: () => _direction = 2, icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white)),
            IconButton(onPressed: () => _direction = 1, icon: const Icon(Icons.keyboard_arrow_right, color: Colors.white)),
          ]),
        ]);
      case 'math':
        final correct = _a + _b;
        return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('$_a + $_b = ؟', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: List.generate(4, (i) {
            final answer = correct + (i - 1) * 2;
            return SizedBox(width: 105, child: FilledButton(onPressed: () {
              if (answer == correct) { _point('إجابة صحيحة!'); setState(_newMath); } else { setState(() => _message = 'حاول مرة ثانية'); }
            }, child: Text('$answer')));
          })),
        ]);
      case 'tunnel':
        return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('غيّر المسار وتفادَ العائق', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 20),
          Row(children: List.generate(3, (i) => Expanded(child: GestureDetector(onTap: () => _hit(i), child: Container(height: 150, margin: const EdgeInsets.all(5), decoration: BoxDecoration(color: _lane == i ? _cyan.withValues(alpha: .2) : Colors.white10, borderRadius: BorderRadius.circular(13), border: Border.all(color: _lane == i ? _cyan : Colors.white12)), child: Center(child: Text(_obstacle == i ? '🚧' : _lane == i ? '🚗' : '·', style: const TextStyle(fontSize: 34))))))),
        ]);
      case 'penalty':
      case 'stars':
      case 'target':
      case 'pingpong':
      case 'hearts':
        return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(widget.game.mode == 'penalty' ? 'اختر زاوية التسديد' : widget.game.mode == 'pingpong' ? 'اضغط لرد الكرة' : 'اضغط واجمع النقاط', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 22),
          if (widget.game.mode == 'pingpong')
            GestureDetector(onTap: () => _hit(1), child: Text(_ballReady ? '🏓' : '✨', style: const TextStyle(fontSize: 90)))
          else
            Row(children: List.generate(3, (i) => Expanded(child: Padding(padding: const EdgeInsets.all(5), child: FilledButton(style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 28), backgroundColor: widget.game.mode != 'hearts' && i == _target ? _purple : const Color(0xFF263453)), onPressed: () => _hit(i), child: Text(widget.game.mode == 'hearts' ? '💗' : widget.game.mode == 'penalty' ? '🥅' : widget.game.mode == 'stars' ? '⭐' : '🎯', style: const TextStyle(fontSize: 29))))))),
        ]);
      default:
        return const Center(child: Text('ابدأ الجولة', style: TextStyle(color: Colors.white)));
    }
  }

  Widget _playerButton(String title, int score, Color color, VoidCallback tap) => Expanded(child: FilledButton(
    style: FilledButton.styleFrom(backgroundColor: color.withValues(alpha: .2), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
    onPressed: tap,
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.touch_app, size: 38), const SizedBox(height: 12), Text(title), const SizedBox(height: 8), Text('$score', style: TextStyle(color: color, fontSize: 30, fontWeight: FontWeight.w900)), const Text('اضغط هنا', style: TextStyle(fontSize: 11))]),
  ));

  String get _instructions => switch (widget.game.mode) {
    'penalty' => 'ابدأ واختر زاوية المرمى. حاول الابتعاد عن جهة الحارس.',
    'tunnel' => 'بدّل المسار بين ثلاثة ممرات وتفادَ العائق.',
    'stars' => 'اضغط النجمة المضيئة واجمع النقاط خلال 30 ثانية.',
    'pingpong' => 'اضغط الكرة حتى تردّها وتحافظ على اللعب.',
    'hearts' => 'اجمع القلوب خلال 30 ثانية.',
    'memory' => 'اكشف بطاقتين وابحث عن الأزواج المتشابهة.',
    'tap' => 'لاعبان على نفس الجهاز؛ أول من يصل إلى 10 ضغطات يفوز.',
    'reaction' => 'انتظر الأخضر؛ الضغط المبكر يعني الخسارة.',
    'code' => 'خمّن الشفرة من أربعة أرقام واستفد من التلميحات.',
    'snake' => 'حرّك الثعبان بالأسهم واجمع الطعام وتجنب الاصطدام.',
    'math' => 'اختر الإجابة الصحيحة لأكبر عدد من المسائل.',
    _ => 'اضغط الهدف الصحيح واجمع أكبر عدد من النقاط.',
  };
}
