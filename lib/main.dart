import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

const live = bool.fromEnvironment('LIVE_ADS', defaultValue: false);
const bottom = 'ca-app-pub-7952445820014663/5123421352';
const top = 'ca-app-pub-7952445820014663/9699739422';
const between = 'ca-app-pub-7952445820014663/7800334393';
const reward = 'ca-app-pub-7952445820014663/1234926048';
const testBanner = 'ca-app-pub-3940256099942544/6300978111';
const testBetween = 'ca-app-pub-3940256099942544/1033173712';
const testReward = 'ca-app-pub-3940256099942544/5224354917';

class Puzzle {
  final String type, question;
  final List<String> options;
  final int answer;
  const Puzzle(this.type, this.question, this.options, this.answer);
}
const puzzles = <Puzzle>[
  Puzzle('منطق','كلما أخذت منه كبر؟',['الحفرة','الكتاب','الشجرة','النهر'],0),
  Puzzle('حساب','7 × 8 = ؟',['54','56','64','48'],1),
  Puzzle('كلمات','عكس شجاع؟',['سريع','قوي','جبان','ذكي'],2),
  Puzzle('معلومات','عدد أيام الأسبوع؟',['5','6','7','8'],2),
  Puzzle('منطق','له أسنان ولا يعض؟',['المشط','القلم','الباب','الحذاء'],0),
  Puzzle('حساب','30 - 12 = ؟',['12','16','18','20'],2),
  Puzzle('كلمات','مرادف السعادة؟',['الفرح','الخوف','الحزن','التعب'],0),
  Puzzle('معلومات','الكوكب الأحمر؟',['الزهرة','المريخ','الأرض','زحل'],1),
  Puzzle('منطق','يكتب ولا يقرأ؟',['الورق','القلم','الكتاب','الهاتف'],1),
  Puzzle('حساب','نصف 90؟',['40','35','45','50'],2),
  Puzzle('كلمات','جمع مدينة؟',['مدينتان','مدائن','مدني','مدينة'],1),
  Puzzle('معلومات','أكبر محيط؟',['الأطلسي','الهندي','الهادئ','المتجمد'],2),
  Puzzle('منطق','له عين ولا يرى؟',['الإبرة','الساعة','النافذة','المرآة'],0),
  Puzzle('حساب','5 × 5 = ؟',['10','20','25','30'],2),
  Puzzle('كلمات','عكس سريع؟',['قريب','بطيء','عاجل','قصير'],1),
  Puzzle('معلومات','عاصمة الأردن؟',['إربد','العقبة','عمّان','الزرقاء'],2),
  Puzzle('منطق','يكسر دون أن تلمسه؟',['الوعد','الزجاج','القلم','الصحن'],0),
  Puzzle('حساب','144 ÷ 12 = ؟',['10','11','12','14'],2),
  Puzzle('كلمات','تبدأ بهمزة قطع؟',['ابن','اسم','أحمد','استمع'],2),
  Puzzle('معلومات','عدد القارات وفق التقسيم الشائع؟',['5','6','7','8'],2),
  Puzzle('منطق','يحترق ويقصر؟',['الشمعة','الحجر','البحر','الجبل'],0),
  Puzzle('حساب','2، 4، 8، 16، ...',['20','24','32','30'],2),
  Puzzle('كلمات','مفرد أشجار؟',['شجرة','شجيرة','شجرات','شجر'],0),
  Puzzle('معلومات','سفينة الصحراء؟',['الحصان','الجمل','الغزال','الفيل'],1),
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Directionality(textDirection: TextDirection.rtl, child: Game()),
  ));
}

class AdStrip extends StatefulWidget {
  final bool upper;
  const AdStrip({super.key, required this.upper});
  @override
  State<AdStrip> createState() => _AdStripState();
}
class _AdStripState extends State<AdStrip> {
  BannerAd? ad;
  bool ready = false;
  @override
  void initState() {
    super.initState();
    final item = BannerAd(
      adUnitId: live ? (widget.upper ? top : bottom) : testBanner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) { if (mounted) setState(() => ready = true); },
        onAdFailedToLoad: (failed, _) {
          failed.dispose();
          if (mounted) setState(() { ad = null; ready = false; });
        },
      ),
    );
    ad = item;
    item.load();
  }
  @override
  void dispose() { ad?.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ready && ad != null
      ? SizedBox(width: ad!.size.width.toDouble(), height: ad!.size.height.toDouble(), child: AdWidget(ad: ad!))
      : const SizedBox.shrink();
}

class Game extends StatefulWidget {
  const Game({super.key});
  @override
  State<Game> createState() => _GameState();
}
class _GameState extends State<Game> {
  int level = 0, points = 0;
  int? chosen;
  bool answered = false;
  InterstitialAd? interstitial;
  RewardedAd? rewarded;
  bool rewardShowing = false;
  @override
  void initState() {
    super.initState();
    _restore();
    _loadBetween();
    _loadReward();
  }
  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      level = (prefs.getInt('level') ?? 0).clamp(0, puzzles.length);
      points = prefs.getInt('points') ?? 0;
    });
  }
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('level', level);
    await prefs.setInt('points', points);
  }
  void _notice(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
  void _loadBetween() {
    InterstitialAd.load(
      adUnitId: live ? between : testBetween,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) { if (!mounted) { ad.dispose(); return; } interstitial?.dispose(); interstitial = ad; },
        onAdFailedToLoad: (_) { interstitial = null; },
      ),
    );
  }
  void _showBetween() {
    final ad = interstitial;
    if (ad == null) { _loadBetween(); return; }
    interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) { ad.dispose(); if (mounted) _loadBetween(); },
      onAdFailedToShowFullScreenContent: (ad, _) { ad.dispose(); if (mounted) _loadBetween(); },
    );
    ad.show();
  }
  void _loadReward() {
    RewardedAd.load(
      adUnitId: live ? reward : testReward,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) { if (!mounted) { ad.dispose(); return; } rewarded?.dispose(); rewarded = ad; },
        onAdFailedToLoad: (_) { rewarded = null; },
      ),
    );
  }
  void _watch() {
    if (rewardShowing) return;
    final ad = rewarded;
    if (ad == null) { _notice('الفيديو غير جاهز حالياً'); _loadReward(); return; }
    rewarded = null;
    rewardShowing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) { ad.dispose(); rewardShowing = false; if (mounted) _loadReward(); },
      onAdFailedToShowFullScreenContent: (ad, _) { ad.dispose(); rewardShowing = false; if (mounted) _loadReward(); },
    );
    ad.show(onUserEarnedReward: (_, __) {
      if (!mounted) return;
      setState(() => points += 50);
      _save();
      _notice('حصلت على 50 نقطة!');
    });
  }
  void _choose(int index) {
    if (answered || level >= puzzles.length) return;
    setState(() {
      chosen = index;
      answered = true;
      if (index == puzzles[level].answer) points += 10;
    });
    _save();
  }
  void _hint() {
    if (answered || level >= puzzles.length) return;
    if (points < 20) { _notice('تحتاج إلى 20 نقطة'); return; }
    setState(() { points -= 20; chosen = puzzles[level].answer; answered = true; });
    _save();
  }
  void _next() {
    if (!answered) return;
    setState(() { level++; chosen = null; answered = false; });
    _save();
    if (level % 3 == 0 && level < puzzles.length) _showBetween();
  }
  @override
  void dispose() { interstitial?.dispose(); rewarded?.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final done = level >= puzzles.length;
    final puzzle = done ? null : puzzles[level];
    return Scaffold(
      appBar: AppBar(title: const Text('🧩 تحدي الألغاز'), centerTitle: true),
      body: SafeArea(child: Column(children: [
        const Center(child: AdStrip(upper: true)),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Chip(label: Text('⭐ ' + points.toString() + ' نقطة')),
              Chip(label: Text(done ? 'مكتمل' : 'المرحلة ' + (level + 1).toString() + ' / ' + puzzles.length.toString())),
            ]),
            if (done) ...[
              const SizedBox(height: 36),
              const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
              const Text('أحسنت! أكملت الألغاز', textAlign: TextAlign.center),
              FilledButton(onPressed: () {
                setState(() { level = 0; chosen = null; answered = false; });
                _save();
              }, child: const Text('إعادة اللعب')),
            ] else ...[
              Text(puzzle!.type, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Card(child: Padding(padding: const EdgeInsets.all(24), child: Text(
                puzzle.question, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ))),
              for (var i = 0; i < puzzle.options.length; i++)
                Padding(padding: const EdgeInsets.only(bottom: 9), child: OutlinedButton(
                  onPressed: answered ? null : () => _choose(i),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: answered && i == puzzle.answer ? Colors.green.shade100
                        : answered && i == chosen ? Colors.red.shade100 : null,
                  ),
                  child: Text(puzzle.options[i]),
                )),
              if (answered) ...[
                Text(chosen == puzzle.answer ? 'إجابة صحيحة! +10 نقاط' : 'الإجابة الصحيحة: ' + puzzle.options[puzzle.answer],
                    textAlign: TextAlign.center),
                FilledButton(onPressed: _next, child: const Text('المرحلة التالية')),
              ] else TextButton.icon(
                onPressed: _hint,
                icon: const Icon(Icons.lightbulb_outline),
                label: const Text('تلميح مقابل 20 نقطة'),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: _watch,
              icon: const Icon(Icons.ondemand_video),
              label: const Text('شاهد فيديو واكسب 50 نقطة'),
            ),
            const Text('الفيديو المكافئ اختياري', textAlign: TextAlign.center),
          ]),
        )),
        const Center(child: AdStrip(upper: false)),
      ])),
    );
  }
}
