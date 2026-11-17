# إعداد مكالمات الصوت والفيديو مجاناً (LiveKit + Cloudflare Workers)

هذا المسار لا يحتاج ترقية Firebase إلى Blaze ولا يستخدم Firebase Cloud Functions. التطبيق يحتفظ بتسجيل الدخول عبر Firebase، بينما يتحقق خادم Cloudflare من Firebase ID token ويصدر رمز LiveKit قصير العمر.

## ما تم تجهيزه في التطبيق

- شاشة مكالمات صوتية أو صوت وفيديو من الأقسام.
- رمز غرفة مشترك حتى يدخل الأصدقاء الغرفة نفسها.
- تشغيل/كتم المايكروفون وتشغيل/إيقاف الكاميرا وإنهاء المكالمة.
- التحقق من Firebase ID token على الخادم قبل إصدار LiveKit JWT.
- حفظ رابط خادم إصدار الرموز محلياً داخل التطبيق.
- عدم وضع LiveKit API Secret داخل التطبيق أو GitHub.

## نشر خادم الرموز من الموبايل عبر Cloudflare Dashboard

1. افتح https://dash.cloudflare.com/ وسجّل الدخول أو أنشئ حساباً مجانياً.
2. افتح **Workers & Pages** ثم **Create** ثم **Create Worker**.
3. سمِّ العامل `future-youth-forum-livekit-token` ثم انشر النسخة الأولية.
4. افتح العامل واختر **Edit code**.
5. استبدل الكود التجريبي كاملاً بمحتوى الملف `src/index.js` من هذا المستودع:
   https://github.com/husinalzerjaoe-ship-it/future-youth-forum/blob/feature/v4-complete-profile-stats/workers/livekit-token/src/index.js
6. اضغط Save and Deploy.
7. افتح **Settings → Variables and Secrets** وأضف متغيرين عاديين:
   - `FIREBASE_PROJECT_ID` = `futureyouth-69f8a`
   - `LIVEKIT_URL` = `wss://youth-forum-future-lu43byvc.livekit.cloud`
8. أضف متغيرين من النوع **Secret**:
   - `LIVEKIT_API_KEY`: معرّف المفتاح من LiveKit.
   - `LIVEKIT_API_SECRET`: السر المطابق له. أدخله داخل Cloudflare فقط ولا ترسله لي.
9. احفظ وانشر مرة ثانية، ثم انسخ رابط العامل الذي ينتهي بـ `.workers.dev`.

الخطة المجانية في Cloudflare Workers لها حدود استخدام وCPU، والحصة المنشورة تصل إلى 100,000 طلب يومياً؛ وقد تتغير الحدود. LiveKit Cloud أيضاً له حدود وخطة مستقلة.

## ربط الرابط داخل التطبيق

1. افتح تطبيق ملتقى شباب المستقبل.
2. ادخل إلى الأقسام ثم «مكالمات الصوت والفيديو».
3. اضغط إعداد رابط خادم المكالمات.
4. الصق رابط Worker كاملاً كما طبعه Wrangler، بدون إضافة `/token`.
5. احفظ الرابط.

## اختبار المكالمة

- سجّل الدخول بحسابين مختلفين.
- افتح شاشة المكالمات على الجهازين.
- أدخل رمز الغرفة نفسه في الجهازين، مثل `future-youth-01`.
- اختَر الصوت أو الفيديو ثم ادخل المكالمة.

## حدود الخطة المجانية

Cloudflare Workers Free حالياً يوفر حصة يومية وحدود CPU وموارد. الحصة المنشورة 100,000 طلب يومياً؛ قد تتغير الحدود، وتُطبق شروط الاستخدام العادل. LiveKit Cloud نفسه يبقى خاضعاً لخطة LiveKit وحدودها. لا أضمن أن كل استخدام أو حركة وسائط ستبقى مجانية إلى الأبد.

## الأمان

- لا تستخدم `firebase functions:secrets:set` لهذا المسار.
- لا تنشر Firebase Functions ولا ترقِّ مشروع Firebase إلى Blaze.
- لا تضف LiveKit API Secret إلى Flutter أو GitHub Secrets أو ملفات المشروع.
- إذا تسرب API Secret، ألغِ المفتاح القديم وأنشئ زوج مفاتيح جديداً من LiveKit.
