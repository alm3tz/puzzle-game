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
  runApp(MaterialApp(
    title: 'رحلة الألغاز',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xff190d36),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffa755f7), brightness: Brightness.dark),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xff301357), foregroundColor: Color(0xffffdb81)),
    ),
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
  const palette=<Color>[Color(0xff306f60),Color(0xff2d6286),Color(0xff75538f),Color(0xff306c9b),Color(0xff986235),Color(0xff734c98),Color(0xff377a79),Color(0xff89547a),Color(0xff42699e),Color(0xffa27d39)];
  return ListView.builder(
   padding:const EdgeInsets.all(14),itemCount:10,
   itemBuilder:(context,region){
    final start=region*50;
    final count=completed.where((i)=>i>=start&&i<start+50).length;
    return Container(
     margin:const EdgeInsets.only(bottom:20),
     decoration:BoxDecoration(
      gradient:LinearGradient(colors:[palette[region],const Color(0xff241344)],begin:Alignment.topLeft,end:Alignment.bottomRight),
      borderRadius:BorderRadius.circular(28),
      border:Border.all(color:const Color(0xffffd77e),width:2),
      boxShadow:const [BoxShadow(color:Colors.black38,blurRadius:12,offset:Offset(0,5))]),
     child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[
      Text('✦ '+regions[region]+' ✦',textAlign:TextAlign.center,
       style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900,color:Color(0xffffd77e))),
      Text('المراحل '+(start+1).toString()+' – '+(start+50).toString()+'   •   '+count.toString()+'/50',
       style:const TextStyle(color:Colors.white70)),
      const SizedBox(height:14),
      for(var row=0;row<10;row++)
       SizedBox(height:62,child:Stack(children:[
        Positioned.fill(child:CustomPaint(painter:_TrailPainter(row))),
        Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[
         for(var col=0;col<5;col++)
          Builder(builder:(context){
           final index=start+row*5+(row.isEven?col:4-col);
           final locked=index>opened,done=completed.contains(index);
           return InkWell(onTap:locked?null:()=>_enter(index),
            borderRadius:BorderRadius.circular(40),
            child:Container(width:48,height:48,
             decoration:BoxDecoration(shape:BoxShape.circle,
              gradient:LinearGradient(colors:locked?[const Color(0xff858197),const Color(0xff353047)]
               :done?[const Color(0xffffe892),const Color(0xffc78419)]
               :[const Color(0xffd889ff),const Color(0xff7134b7)]),
              border:Border.all(color:locked?Colors.white38:const Color(0xffffe49c),width:2.4),
              boxShadow:locked?[]:[const BoxShadow(color:Colors.black38,blurRadius:7,offset:Offset(0,3))]),
             child:Center(child:locked?const Icon(Icons.lock,color:Colors.white70,size:19):
              done?const Icon(Icons.star,color:Color(0xff62370b),size:25):
              Text((index+1).toString(),style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900))),
            ));
          }),
        ]),
       ])),
     ])),
    );
   },
  );
 }
 Widget _play(){
  final p=puzzles[level];
  return SingleChildScrollView(padding:const EdgeInsets.all(18),
   child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Center(child:Container(padding:const EdgeInsets.symmetric(horizontal:25,vertical:12),
     decoration:BoxDecoration(color:const Color(0xff80369b),borderRadius:BorderRadius.circular(22),
      border:Border.all(color:const Color(0xffffd67c),width:2)),
     child:Text('المرحلة '+(level+1).toString()+' • '+p.category,
      style:const TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.bold)))),
    const SizedBox(height:24),
    Container(padding:const EdgeInsets.symmetric(horizontal:20,vertical:35),
     decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xffffe7b7),Color(0xffffc77c)]),
      borderRadius:BorderRadius.circular(22),border:Border.all(color:const Color(0xffffb54c),width:3),
      boxShadow:const [BoxShadow(color:Colors.black38,blurRadius:12,offset:Offset(0,6))]),
     child:Text(p.question,textAlign:TextAlign.center,
      style:const TextStyle(fontSize:23,fontWeight:FontWeight.w900,color:Color(0xff322047)))),
    const SizedBox(height:22),
    for(var i=0;i<4;i++)
     Padding(padding:const EdgeInsets.only(bottom:12),child:Material(color:Colors.transparent,
      child:InkWell(onTap:answered?null:()=>_choose(i),borderRadius:BorderRadius.circular(18),
       child:Container(padding:const EdgeInsets.all(17),
        decoration:BoxDecoration(color:answered&&i==p.correct?const Color(0xffa6e8ae):
         answered&&i==chosen?const Color(0xffffa7a7):const Color(0xffffd9a3),
         borderRadius:BorderRadius.circular(18),border:Border.all(color:const Color(0xffd29a57),width:2)),
        child:Text(p.options[i],textAlign:TextAlign.center,
         style:const TextStyle(color:Color(0xff322047),fontSize:18,fontWeight:FontWeight.bold)))))),
    if(answered)...[
     Text(chosen==p.correct?'🌟 أحسنت! إجابة صحيحة':'حاول مرة أخرى!',
      textAlign:TextAlign.center,style:const TextStyle(fontSize:19,color:Color(0xffffd67c))),
     _gameButton(chosen==p.correct?'المرحلة التالية':'إعادة المحاولة',_next),
    ]else _gameButton('💡 تلميح — 20 نقطة',_hint,purple:true),
   ]));
 }
 Widget _gameButton(String label,VoidCallback callback,{bool purple=false})=>
  Container(margin:const EdgeInsets.symmetric(vertical:6),
   decoration:BoxDecoration(gradient:LinearGradient(colors:purple?
    [const Color(0xffac65ec),const Color(0xff702eb0)]:
    [const Color(0xff80e958),const Color(0xff1b9633)]),
    borderRadius:BorderRadius.circular(18),
    border:Border.all(color:purple?const Color(0xffd6a6ff):const Color(0xffbcff91),width:2)),
   child:TextButton(onPressed:callback,
    child:Padding(padding:const EdgeInsets.symmetric(vertical:8),
     child:Text(label,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:17)))));
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
   LinearProgressIndicator(value:completed.length/500,color:const Color(0xffffd47a),backgroundColor:const Color(0xff483061),minHeight:7),
   Expanded(child:inGame?_play():_map()),
   Padding(padding:const EdgeInsets.symmetric(horizontal:20),child:_gameButton('🎁 فيديو مكافأة — 50 نقطة',_watch)),
   const Center(child:AdStrip(upper:false)),
  ])),
 );
}

class _TrailPainter extends CustomPainter {
 final int row;
 const _TrailPainter(this.row);
 @override void paint(Canvas canvas,Size size){
  final paint=Paint()..color=const Color(0x99ffcd73)..strokeWidth=9..strokeCap=StrokeCap.round..style=PaintingStyle.stroke;
  final path=Path()..moveTo(size.width*.1,size.height*.5);
  path.cubicTo(size.width*.3,row.isEven?4:size.height-4,
   size.width*.7,row.isEven?size.height-4:4,size.width*.9,size.height*.5);
  canvas.drawPath(path,paint);
 }
 @override bool shouldRepaint(covariant _TrailPainter old)=>old.row!=row;
}
