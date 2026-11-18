# تحدي الألغاز — إعداد المشروع

نسخة أولية من لعبة ألغاز عربية (24 مرحلة)، مع نقاط محفوظة محلياً وGoogle AdMob.

## Android Studio

1. ثبّت Flutter وAndroid Studio.
2. من جذر المستودع شغّل: `flutter create --platforms=android --org com.alm3tz .`
3. في `android/app/src/main/AndroidManifest.xml` أضف داخل `<application>`:
   `<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="ca-app-pub-7952445820014663~9340646779" />`
4. أضف `<uses-permission android:name="android.permission.INTERNET" />` داخل `<manifest>`.
5. شغّل `flutter pub get` ثم `flutter run`.

## الإعلانات

- أسفل: `ca-app-pub-7952445820014663/5123421352`
- أعلى: `ca-app-pub-7952445820014663/9699739422`
- بين المراحل: `ca-app-pub-7952445820014663/7800334393`
- مكافأة 50 نقطة: `ca-app-pub-7952445820014663/1234926048`

الافتراضي يستخدم معرّفات Google التجريبية. للإنتاج فقط:
`flutter build apk --release --dart-define=LIVE_ADS=true`

قبل النشر يجب اختبار التطبيق، إضافة متطلبات الخصوصية والموافقة الإعلانية المناسبة، وعدم النقر على إعلاناتك الحقيقية. لم يتم اختبار بناء APK في هذه البيئة.
