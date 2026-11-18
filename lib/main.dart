import 'dart:math' as math;
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
 int level=0,points=10,opened=0;
 String daily='';
 final Set<int> hidden={};
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
   points=p.getInt('points')??10;
   daily=p.getString('daily')??'';
   sounds=p.getBool('sounds')??true;
   completed.addAll((p.getStringList('completed')??[]).map(int.tryParse).whereType<int>().where((n)=>n>=0&&n<500));
  });
 }
 Future<void> _save()async{
  final p=await SharedPreferences.getInstance();
  await p.setInt('opened',opened);
  await p.setInt('points',points);
  await p.setString('daily',daily);
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

 Future<void> _popup(String title,String message)async{
  if(!mounted)return;
  await showDialog<void>(context:context,builder:(ctx)=>AlertDialog(
   backgroundColor:const Color(0xff39215d),
   title:Text(title,textAlign:TextAlign.center,style:const TextStyle(color:Color(0xffffd87a))),
   content:Text(message,textAlign:TextAlign.center),
   actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('متابعة'))]));
 }
 void _daily(){
  final now=DateTime.now();
  final today=now.year.toString()+'-'+now.month.toString()+'-'+now.day.toString();
  if(daily==today){_popup('🎁 المكافأة اليومية','استلمت مكافأتك اليوم، عد غداً!');return;}
  setState((){points+=30;daily=today;});_save();
  _popup('🎁 مكافأة يومية','حصلت على 30 نقطة!');
 }
 void _enter(int n){
  if(n>opened||n>=500)return;
  final newRegion=n>0&&n%50==0&&level!=n;
  setState((){level=n;chosen=null;answered=false;inGame=true;hidden.clear();});
  if(newRegion)WidgetsBinding.instance.addPostFrameCallback((_){
   if(mounted)_popup('🌟 مرحباً في '+regions[n~/50],'بدأت مغامرة جديدة من 50 مرحلة!');
  });
 }
 void _choose(int n){
  if(answered||hidden.contains(n))return;
  final good=n==puzzles[level].correct;
  setState((){
   chosen=n;answered=true;
   if(good){
    if(!completed.contains(level)){
     completed.add(level);points+=10;
     if(level==opened)opened=(opened+1).clamp(0,500);
    }
   }else{points=(points-20).clamp(0,99999999);}
  });
  _save();
  _popup(good?'🌟 إجابة صحيحة':'❌ إجابة خاطئة',
   good?'أحسنت! انتقل للمرحلة التالية.':'خسرت 20 نقطة. حاول مجدداً.');
 }
 void _hint(){
  if(answered)return;
  if(points<50){_popup('نقاط غير كافية','تحتاج إلى 50 نقطة.');return;}
  setState(()=>points-=50);_save();
  _popup('💡 الإجابة',puzzles[level].options[puzzles[level].correct]);
 }
 void _removeTwo(){
  if(answered||hidden.isNotEmpty)return;
  if(points<20){_popup('نقاط غير كافية','تحتاج إلى 20 نقطة.');return;}
  final correct=puzzles[level].correct;
  setState((){
   points-=20;
   hidden.addAll([0,1,2,3].where((i)=>i!=correct).take(2));
  });_save();
 }
 void _next(){
  if(chosen!=puzzles[level].correct){
   setState((){answered=false;chosen=null;});return;
  }
  final n=level+1;
  setState((){inGame=false;answered=false;chosen=null;hidden.clear();});
  if(n<500&&n<=opened)_enter(n);
  if(n%5==0&&n<500)_showBetween();
  if(n==500)_popup('🏆 تهانينا','أكملت جميع المراحل!');
 }
 @override void dispose(){interstitial?.dispose();rewarded?.dispose();super.dispose();}

 Widget _map(){
  const palette=<Color>[Color(0xff397b65),Color(0xff386d90),Color(0xff8262a8),
   Color(0xff327f95),Color(0xffb0874d),Color(0xff7055a6),
   Color(0xff36867b),Color(0xff906a88),Color(0xff4e7caa),Color(0xffb08c46)];
  return ListView.builder(padding:const EdgeInsets.all(12),itemCount:10,
   itemBuilder:(context,region){
    final start=region*50;
    final count=completed.where((i)=>i>=start&&i<start+50).length;
    return Container(margin:const EdgeInsets.only(bottom:18),
     decoration:BoxDecoration(
      gradient:LinearGradient(colors:[palette[region],const Color(0xff201339)]),
      borderRadius:BorderRadius.circular(28),
      border:Border.all(color:const Color(0xffffd47b),width:2)),
     child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[
      Text('✦ '+regions[region]+' ✦',style:const TextStyle(fontSize:21,
       fontWeight:FontWeight.bold,color:Color(0xffffd77e))),
      Text('المنطقة '+(region+1).toString()+'  •  '+count.toString()+'/50',
       style:const TextStyle(color:Colors.white70)),
      const SizedBox(height:12),
      SizedBox(height:1100,child:LayoutBuilder(builder:(context,c){
       final width=c.maxWidth;
       Offset pos(int i){
        final t=i/49.0;
        return Offset(width*(.5+.34*math.sin(i*math.pi/8)),1070-t*1040);
       }
       return Stack(children:[
        Positioned.fill(child:CustomPaint(painter:_WindingRoadPainter(
         List.generate(50,pos)))),
        for(var i=0;i<50;i++)
         Positioned(left:pos(i).dx-23,top:pos(i).dy-23,
          child:Builder(builder:(context){
           final index=start+i,locked=index>opened,done=completed.contains(index);
           return GestureDetector(onTap:locked?null:()=>_enter(index),
            child:Container(width:46,height:46,
             decoration:BoxDecoration(shape:BoxShape.circle,
              gradient:LinearGradient(colors:locked?
               [const Color(0xff797286),const Color(0xff3e3954)]:
               done?[const Color(0xffffe68d),const Color(0xffcf8b22)]:
               [const Color(0xffdc8cff),const Color(0xff8036c0)]),
              border:Border.all(color:locked?Colors.white38:const Color(0xffffe4a0),width:2.4),
              boxShadow:const [BoxShadow(color:Colors.black38,blurRadius:6)]),
             child:Center(child:locked?const Icon(Icons.lock,size:17,color:Colors.white70):
              done?const Icon(Icons.star,color:Color(0xff70400d)):
              Text((index+1).toString(),style:const TextStyle(fontSize:13,
               fontWeight:FontWeight.bold,color:Colors.white))))));
          })),
       ]);
      })),
     ])));
   });
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

class _WindingRoadPainter extends CustomPainter{
 final List<Offset> points;
 const _WindingRoadPainter(this.points);
 @override void paint(Canvas canvas,Size size){
  final path=Path()..moveTo(points.first.dx,points.first.dy);
  for(var i=1;i<points.length;i++){
   final a=points[i-1],b=points[i];
   path.lineTo(b.dx,b.dy);
  }
  canvas.drawPath(path,Paint()..color=const Color(0xff674726)
   ..strokeWidth=31..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round
   ..style=PaintingStyle.stroke);
  canvas.drawPath(path,Paint()..color=const Color(0xffe5b86d)
   ..strokeWidth=23..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round
   ..style=PaintingStyle.stroke);
 }
 @override bool shouldRepaint(covariant _WindingRoadPainter old)=>false;
}
