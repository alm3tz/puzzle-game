class Puzzle {
 final String category, question;
 final List<String> options;
 final int correct;
 const Puzzle(this.category,this.question,this.options,this.correct);
}
const regions=['وادي البداية','غابة الأفكار','جبال الحساب','بحيرة الكلمات','صحراء الأسرار','مدينة الأذكياء','جزيرة التحديات','قلعة المنطق','سماء المعرفة','قمة الأبطال'];
final opposites=<List<String>>[
['شجاع','جبان'],['سريع','بطيء'],['طويل','قصير'],['كبير','صغير'],['حار','بارد'],
['نهار','ليل'],['سهل','صعب'],['قديم','جديد'],['قريب','بعيد'],['فرح','حزن'],
['قوي','ضعيف'],['فوق','تحت'],['داخل','خارج'],['ممتلئ','فارغ'],['صعود','هبوط'],
['فتح','إغلاق'],['نور','ظلام'],['نجاح','فشل'],['بداية','نهاية'],['صادق','كاذب']
];
Puzzle numeric(String type,String question,int result,int seed) {
 final values=[result,result+1,result+3+seed%5,result-1-seed%3];
 final rotated=List.generate(4,(i)=>values[(i+seed%4)%4].toString());
 return Puzzle(type,question,rotated,rotated.indexOf(result.toString()));
}
List<Puzzle> buildLevels()=>List.generate(500,(index){
 final n=index+1;
 switch(index%5) {
 case 0:
 final a=8+n*3,b=4+(n*7)%31;
 return numeric('حساب','ما ناتج $a + $b ؟',a+b,n);
 case 1:
 final a=n*2+1,b=2+n%9;
 return numeric('أنماط','أكمل: $a، ${a+b}، ${a+b*2}، ...',a+b*3,n);
 case 2:
 final a=4+n%19,b=3+(n*3)%17;
 return numeric('ذكاء','لديك $a مجموعات بكل منها $b عناصر، كم المجموع؟',a*b,n);
 case 3:
 final a=15+n*2,b=3+n%13;
 return numeric('منطق عددي','ما العدد الذي يزيد عن $a بمقدار $b؟',a+b,n);
 default:
 final pair=opposites[(n~/5)%opposites.length],other=opposites[((n~/5)+7)%opposites.length];
 final values=[pair[1],other[0],other[1],pair[0]];
 final shifted=List.generate(4,(i)=>values[(i+n%4)%4]);
 return Puzzle('كلمات','ما عكس كلمة «${pair[0]}»؟',shifted,shifted.indexOf(pair[1]));
 }
});
