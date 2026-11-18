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
 int dailyStreak=0;
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
   dailyStreak=p.getInt('daily_streak')??(daily.isEmpty?0:1);
   sounds=p.getBool('sounds')??true;
   completed.addAll((p.getStringList('completed')??[]).map(int.tryParse).whereType<int>().where((n)=>n>=0&&n<500));
  });
 }
 Future<void> _save()async{
  final p=await SharedPreferences.getInstance();
  await p.setInt('opened',opened);
  await p.setInt('points',points);
  await p.setString('daily',daily);
  await p.setInt('daily_streak',dailyStreak);
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
  final today=DateTime(now.year,now.month,now.day);
  final todayKey='${today.year}-${today.month}-${today.day}';
  final previous=DateTime.tryParse(daily);
  final days=previous==null?null:today.difference(previous).inDays;
  final currentStreak=days==null?0:(days==0?dailyStreak:days==1?dailyStreak:0);
  if(days==0){
   _popup('🔥 $currentStreak يوم متواصل','لقد استلمت مكافأتك اليومية، عد غداً!');
   return;
  }
  setState((){
   dailyStreak=days==1?dailyStreak+1:1;
   daily=todayKey;
   points+=30;
  });
  _save();
  _popup('🎁 $dailyStreak يوم متواصل','حصلت على 30 نقطة! عد غداً للحفاظ على سلسلة المكافآت.');
 }
 void _enter(int n){
  if(n>opened||n>=500)return;
  final newRegion=n>0&&n%50==0&&level!=n;
  setState((){level=n;chosen=null;answered=false;inGame=true;hidden.clear();});
  if(newRegion){ WidgetsBinding.instance.addPostFrameCallback((_){
   if(mounted)_popup('🌟 مرحباً في ${regions[n~/50]}','بدأت مغامرة جديدة من 50 مرحلة!');
  }); }
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
      Text('✦ ${regions[region]} ✦',style:const TextStyle(fontSize:21,
       fontWeight:FontWeight.bold,color:Color(0xffffd77e))),
      Text('المنطقة ${region+1}  •  $count/50',
       style:const TextStyle(color:Colors.white70)),
      const SizedBox(height:12),
      SizedBox(height:2600,child:LayoutBuilder(builder:(context,c){
       final width=c.maxWidth;
       Offset pos(int i){
        final t=i/49.0;
        return Offset(width*(.5+.32*math.sin(i*math.pi/9)),35+t*2530);
       }
       return Stack(children:[
        Positioned.fill(child:CustomPaint(painter:_AdventurePainter(List.generate(50,pos),region))),
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
               fontWeight:FontWeight.bold,color:Colors.white)))));
          })),
       ]);
      })),
     ])));
   });
 }

 Widget _play(){
  final p=puzzles[level];
  return LayoutBuilder(builder:(context,size)=>SingleChildScrollView(
   padding:const EdgeInsets.symmetric(horizontal:14,vertical:8),
   child:ConstrainedBox(constraints:BoxConstraints(minHeight:size.maxHeight),
    child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
     Text('المرحلة ${level+1} • ${p.category}',
      textAlign:TextAlign.center,style:const TextStyle(fontSize:15,color:Color(0xffffd67c))),
     const SizedBox(height:8),
     Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:18),
      decoration:BoxDecoration(gradient:const LinearGradient(
       colors:[Color(0xffffe7b7),Color(0xffffc77c)]),
       borderRadius:BorderRadius.circular(19),
       border:Border.all(color:const Color(0xffffb54c),width:2)),
      child:Text(p.question,textAlign:TextAlign.center,
       style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800,color:Color(0xff322047)))),
     const SizedBox(height:12),
     for(var i=0;i<4;i++)
      Padding(padding:const EdgeInsets.only(bottom:9),
       child:Material(color:Colors.transparent,
        child:InkWell(onTap:answered||hidden.contains(i)?null:()=>_choose(i),
         borderRadius:BorderRadius.circular(15),
         child:Container(padding:const EdgeInsets.symmetric(vertical:11,horizontal:10),
          decoration:BoxDecoration(
           color:hidden.contains(i)?const Color(0xff574d65):
            answered&&i==chosen?
             (chosen==p.correct?const Color(0xffa2e8a9):const Color(0xffffa9a9)):
             const Color(0xffffd9a3),
           borderRadius:BorderRadius.circular(15),
           border:Border.all(color:const Color(0xffd29a57),width:2)),
          child:Text(hidden.contains(i)?'—':p.options[i],textAlign:TextAlign.center,
           style:TextStyle(color:hidden.contains(i)?Colors.white54:const Color(0xff322047),
            fontSize:16,fontWeight:FontWeight.bold)))))),
     if(answered)
      _gameButton(chosen==p.correct?'المرحلة التالية':'إعادة المحاولة',_next),
     const SizedBox(height:4),
     Row(children:[
      Expanded(child:_gameButton('💡 كشف 50',_hint,purple:true)),
      const SizedBox(width:8),
      Expanded(child:_gameButton('✂️ حذف 2 • 20',_removeTwo,purple:true)),
     ]),
    ]))));
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
     child:Text(label,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:13)))));
 @override Widget build(BuildContext context)=>Scaffold(
  appBar:AppBar(
   title:Text(inGame?'المرحلة ${level+1}':'🧩 رحلة الألغاز'),
   centerTitle:true,
   leading:inGame?IconButton(icon:const Icon(Icons.arrow_back),onPressed:()=>setState(()=>inGame=false)):null,
   actions:[IconButton(tooltip:'الصوت',icon:Icon(sounds?Icons.volume_up:Icons.volume_off),
    onPressed:(){setState(()=>sounds=!sounds);_save();})]),
  body:SafeArea(child:Column(children:[
   const Center(child:AdStrip(upper:true)),
   Padding(padding:const EdgeInsets.all(8),child:Row(
    mainAxisAlignment:MainAxisAlignment.spaceAround,
    children:[Chip(label:Text('⭐ $points نقطة')),
     Chip(label:Text('🏆 ${completed.length} / 500'))])),
   LinearProgressIndicator(value:completed.length/500,color:const Color(0xffffd47a),backgroundColor:const Color(0xff483061),minHeight:7),
   Expanded(child:inGame?_play():_map()),
   if(!inGame)Row(children:[
    Expanded(child:TextButton.icon(onPressed:_daily,
     icon:const Icon(Icons.local_fire_department,size:17),
     label:Text('مكافأة يومية • $dailyStreak يوم',style:const TextStyle(fontSize:12)))),
    Expanded(child:TextButton.icon(onPressed:_watch,
     icon:const Icon(Icons.smart_display,size:17),
     label:const Text('فيديو +50',style:TextStyle(fontSize:12)))),
   ]) else Align(alignment:Alignment.center,
    child:TextButton.icon(onPressed:_watch,
     icon:const Icon(Icons.smart_display,size:17),
     label:const Text('فيديو مكافأة +50',style:TextStyle(fontSize:12)))),
   const Center(child:AdStrip(upper:false)),
  ])),
 );
}


class _AdventurePainter extends CustomPainter {
 final List<Offset> points;
 final int region;
 const _AdventurePainter(this.points,this.region);
 @override void paint(Canvas canvas,Size size){
  final rng=math.Random(region+41);
  final sky=Paint()..color=const Color(0x3349d5b6);
  canvas.drawCircle(Offset(size.width*.82,70),45,sky);
  for(var i=0;i<19;i++){
   final x=rng.nextDouble()*size.width;
   final y=i*140.0+25;
   _mountain(canvas,Offset(x,y),28+rng.nextDouble()*33,
    i.isEven?const Color(0xff7087a4):const Color(0xff4b6c7e));
  }
  for(var i=0;i<210;i++){
   final x=12+rng.nextDouble()*(size.width-24);
   final y=20+rng.nextDouble()*(size.height-40);
   final near=points.any((p)=>(p-Offset(x,y)).distance<39);
   if(near)continue;
   if(region%3==2&&i%4==0){
    _rock(canvas,Offset(x,y),9+rng.nextDouble()*12);
   }else{
    _tree(canvas,Offset(x,y),7+rng.nextDouble()*9,
     i.isEven?const Color(0xff216b4b):const Color(0xff15503c));
   }
  }
  for(var i=0;i<4;i++){
   final y=280+i*610.0;
   final x=i.isEven?size.width*.13:size.width*.86;
   _castle(canvas,Offset(x,y),region.isEven?const Color(0xffd8c1a2):const Color(0xffa9a4cb));
  }
  final road=Path()..moveTo(points.first.dx,points.first.dy);
  for(var i=1;i<points.length;i++){
   final a=points[i-1],b=points[i];
   final mid=Offset((a.dx+b.dx)/2,(a.dy+b.dy)/2);
   road.quadraticBezierTo(a.dx,a.dy,mid.dx,mid.dy);
  }
  road.lineTo(points.last.dx,points.last.dy);
  canvas.drawPath(road,Paint()..color=const Color(0xff644524)
   ..strokeWidth=35..strokeCap=StrokeCap.round..style=PaintingStyle.stroke);
  canvas.drawPath(road,Paint()..color=const Color(0xfff0c57d)
   ..strokeWidth=27..strokeCap=StrokeCap.round..style=PaintingStyle.stroke);
  canvas.drawPath(road,Paint()..color=const Color(0xfff9dfaa)
   ..strokeWidth=2..strokeCap=StrokeCap.round..style=PaintingStyle.stroke);
 }
 void _mountain(Canvas c,Offset o,double r,Color color){
  final p=Path()..moveTo(o.dx-r,o.dy+r*.55)..lineTo(o.dx,o.dy-r)
   ..lineTo(o.dx+r,o.dy+r*.55)..close();
  c.drawPath(p,Paint()..color=color.withValues(alpha:.55));
  final snow=Path()..moveTo(o.dx-r*.23,o.dy-r*.55)..lineTo(o.dx,o.dy-r)
   ..lineTo(o.dx+r*.26,o.dy-r*.51)..lineTo(o.dx,o.dy-r*.64)..close();
  c.drawPath(snow,Paint()..color=const Color(0xfff4f1e9).withValues(alpha:.8));
 }
 void _tree(Canvas c,Offset o,double r,Color green){
  c.drawRRect(RRect.fromRectAndRadius(
   Rect.fromCenter(center:o.translate(0,r*.4),width:r*.34,height:r*1.3),
   const Radius.circular(2)),Paint()..color=const Color(0xff6b432c));
  for(var j=0;j<3;j++){
   final y=o.dy-r*.4+j*r*.42;
   final w=r*(.68+j*.23);
   final p=Path()..moveTo(o.dx,y-r*.8)
    ..lineTo(o.dx-w,y+r*.45)..lineTo(o.dx+w,y+r*.45)..close();
   c.drawPath(p,Paint()..color=green);
  }
 }
 void _rock(Canvas c,Offset o,double r){
  final p=Path()..moveTo(o.dx-r,o.dy+r*.4)..lineTo(o.dx-r*.5,o.dy-r*.5)
   ..lineTo(o.dx+r*.4,o.dy-r*.8)..lineTo(o.dx+r,o.dy+r*.3)..close();
  c.drawPath(p,Paint()..color=const Color(0xffa4a2a9));
  c.drawLine(o.translate(-r*.5,-r*.5),o.translate(r*.1,r*.2),
   Paint()..color=const Color(0xff747583)..strokeWidth=2);
 }
 void _castle(Canvas c,Offset o,Color stone){
  final p=Paint()..color=stone;
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx-19,o.dy-7,38,31),
   const Radius.circular(3)),p);
  for(final dx in [-21.0,13.0]){
   c.drawRect(Rect.fromLTWH(o.dx+dx,o.dy-19,9,40),p);
   c.drawRect(Rect.fromLTWH(o.dx+dx-2,o.dy-23,13,7),p);
  }
  final roof=Path()..moveTo(o.dx-9,o.dy-7)..lineTo(o.dx,o.dy-28)
   ..lineTo(o.dx+9,o.dy-7)..close();
  c.drawPath(roof,Paint()..color=const Color(0xff9a4266));
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx-5,o.dy+7,10,17),
   const Radius.circular(5)),Paint()..color=const Color(0xff4d334c));
  c.drawRect(Rect.fromLTWH(o.dx+18,o.dy-28,2,15),
   Paint()..color=const Color(0xfff6e1a0));
  final flag=Path()..moveTo(o.dx+20,o.dy-28)..lineTo(o.dx+33,o.dy-23)
   ..lineTo(o.dx+20,o.dy-19)..close();
  c.drawPath(flag,Paint()..color=const Color(0xffffd36b));
 }
 @override bool shouldRepaint(covariant _AdventurePainter old)=>old.region!=region;
}
