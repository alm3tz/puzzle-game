import 'levels.dart';
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

final puzzles = buildLevels();

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
 @override State<Game> createState()=>_GameState();
}
class _GameState extends State<Game> {
 int level=0,points=0,opened=0;
 bool inGame=false,answered=false,rewardShowing=false,sounds=true;
 int? chosen;
 final Set<int> completed={};
 InterstitialAd? interstitial;
 RewardedAd? rewarded;
 @override void initState(){super.initState();_restore();_loadBetween();_loadReward();}
 Future<void> _restore() async {
  final p=await SharedPreferences.getInstance();
  if(!mounted)return;
  setState((){
   opened=(p.getInt('opened')??p.getInt('level')??0).clamp(0,500);
   points=p.getInt('points')??0;
   sounds=p.getBool('sounds')??true;
   completed.addAll((p.getStringList('completed')??[]).map(int.tryParse).whereType<int>().where((n)=>n>=0&&n<500));
  });
 }
 Future<void> _save()async{
  final p=await SharedPreferences.getInstance();
  await p.setInt('opened',opened);
  await p.setInt('points',points);
  await p.setBool('sounds',sounds);
  await p.setStringList('completed',completed.map((n)=>n.toString()).toList());
 }
 void _notice(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}
 void _loadBetween(){
  InterstitialAd.load(adUnitId:live?between:testBetween,request:const AdRequest(),
   adLoadCallback:InterstitialAdLoadCallback(
    onAdLoaded:(ad){if(!mounted){ad.dispose();return;}interstitial?.dispose();interstitial=ad;},
    onAdFailedToLoad:(_){interstitial=null;}));
 }
 void _showBetween(){
  final ad=interstitial;
  if(ad==null){_loadBetween();return;}
  interstitial=null;
  ad.fullScreenContentCallback=FullScreenContentCallback(
   onAdDismissedFullScreenContent:(ad){ad.dispose();if(mounted)_loadBetween();},
   onAdFailedToShowFullScreenContent:(ad,_){ad.dispose();if(mounted)_loadBetween();});
  ad.show();
 }
 void _loadReward(){
  RewardedAd.load(adUnitId:live?reward:testReward,request:const AdRequest(),
   rewardedAdLoadCallback:RewardedAdLoadCallback(
    onAdLoaded:(ad){if(!mounted){ad.dispose();return;}rewarded?.dispose();rewarded=ad;},
    onAdFailedToLoad:(_){rewarded=null;}));
 }
 void _watch(){
  if(rewardShowing)return;
  final ad=rewarded;
  if(ad==null){_notice('الفيديو غير متاح حالياً');_loadReward();return;}
  rewarded=null;rewardShowing=true;
  ad.fullScreenContentCallback=FullScreenContentCallback(
   onAdDismissedFullScreenContent:(ad){ad.dispose();rewardShowing=false;if(mounted)_loadReward();},
   onAdFailedToShowFullScreenContent:(ad,_){ad.dispose();rewardShowing=false;if(mounted)_loadReward();});
  ad.show(onUserEarnedReward:(_,__){
   if(!mounted)return;
   setState(()=>points+=50);_save();_notice('ربحت 50 نقطة!');
  });
 }
 void _enter(int n){
  if(n>opened||n>=500)return;
  setState((){level=n;chosen=null;answered=false;inGame=true;});
 }
 void _choose(int n){
  if(answered)return;
  final good=n==puzzles[level].correct;
  setState((){
   chosen=n;answered=true;
   if(good&&!completed.contains(level)){
    completed.add(level);points+=10;
    if(level==opened)opened=(opened+1).clamp(0,500);
   }
  });
  _save();
 }
 void _hint(){
  if(answered)return;
  if(points<20){_notice('تحتاج إلى 20 نقطة');return;}
  setState(()=>points-=20);_save();
  _notice('الإجابة: '+puzzles[level].options[puzzles[level].correct]);
 }
 void _next(){
  if(chosen!=puzzles[level].correct){setState((){answered=false;chosen=null;});return;}
  final n=level+1;
  setState((){inGame=false;answered=false;chosen=null;});
  if(n<500&&n<=opened)_enter(n);
  if(n%5==0&&n<500)_showBetween();
  if(n==500)_notice('مبروك! أكملت جميع المراحل');
 }
 @override void dispose(){interstitial?.dispose();rewarded?.dispose();super.dispose();}
 Widget _map(){
  return ListView.builder(
   padding:const EdgeInsets.all(12),itemCount:10,
   itemBuilder:(context,region)=>Card(
    margin:const EdgeInsets.only(bottom:16),
    child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[
     Text('🌍 '+regions[region],style:Theme.of(context).textTheme.titleLarge),
     const SizedBox(height:12),
     for(var row=0;row<10;row++)
      Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[
       for(var col=0;col<5;col++)
        Builder(builder:(context){
         final index=region*50+row*5+(row.isEven?col:4-col);
         final locked=index>opened,done=completed.contains(index);
         return Padding(padding:const EdgeInsets.symmetric(vertical:5),child:
          InkWell(onTap:locked?null:()=>_enter(index),
           borderRadius:BorderRadius.circular(40),
           child:CircleAvatar(radius:23,
            backgroundColor:done?Colors.green.shade200:locked?Colors.grey.shade300:Theme.of(context).colorScheme.primaryContainer,
            child:locked?const Icon(Icons.lock,size:17):done?const Icon(Icons.star,size:20):Text((index+1).toString(),style:const TextStyle(fontSize:12)),
           )));
        }),
      ]),
    ])),
   ),
  );
 }
 Widget _play(){
  final p=puzzles[level];
  return SingleChildScrollView(padding:const EdgeInsets.all(16),child:
   Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Text('المرحلة '+(level+1).toString()+' / 500 — '+p.category,textAlign:TextAlign.center),
    const SizedBox(height:16),
    Card(child:Padding(padding:const EdgeInsets.all(24),child:Text(p.question,
     textAlign:TextAlign.center,style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)))),
    const SizedBox(height:16),
    for(var i=0;i<4;i++)
     Padding(padding:const EdgeInsets.only(bottom:8),child:OutlinedButton(
      onPressed:answered?null:()=>_choose(i),
      style:OutlinedButton.styleFrom(padding:const EdgeInsets.all(16),
       backgroundColor:answered&&i==p.correct?Colors.green.shade100:
        answered&&i==chosen?Colors.red.shade100:null),
      child:Text(p.options[i]))),
    if(answered)...[
     Text(chosen==p.correct?'إجابة صحيحة! ⭐':'إجابة غير صحيحة. حاول مجدداً.',textAlign:TextAlign.center),
     FilledButton(onPressed:_next,child:Text(chosen==p.correct?'المرحلة التالية':'إعادة المحاولة')),
    ]else TextButton.icon(onPressed:_hint,icon:const Icon(Icons.lightbulb_outline),
     label:const Text('تلميح مقابل 20 نقطة')),
   ]));
 }
 @override Widget build(BuildContext context)=>Scaffold(
  appBar:AppBar(
   title:Text(inGame?'المرحلة '+(level+1).toString():'🧩 رحلة الألغاز'),
   centerTitle:true,
   leading:inGame?IconButton(icon:const Icon(Icons.arrow_back),onPressed:()=>setState(()=>inGame=false)):null,
   actions:[IconButton(tooltip:'الصوت',icon:Icon(sounds?Icons.volume_up:Icons.volume_off),
    onPressed:(){setState(()=>sounds=!sounds);_save();})]),
  body:SafeArea(child:Column(children:[
   const Center(child:AdStrip(upper:true)),
   Padding(padding:const EdgeInsets.all(8),child:Row(
    mainAxisAlignment:MainAxisAlignment.spaceAround,
    children:[Chip(label:Text('⭐ '+points.toString()+' نقطة')),
     Chip(label:Text('🏆 '+completed.length.toString()+' / 500'))])),
   LinearProgressIndicator(value:completed.length/500),
   Expanded(child:inGame?_play():_map()),
   FilledButton.tonalIcon(onPressed:_watch,icon:const Icon(Icons.ondemand_video),
    label:const Text('فيديو مكافأة — 50 نقطة')),
   const Center(child:AdStrip(upper:false)),
  ])),
 );
}
