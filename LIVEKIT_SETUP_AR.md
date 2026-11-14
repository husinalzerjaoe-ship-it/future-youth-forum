# إعداد مكالمات الصوت والفيديو مجاناً (LiveKit + Cloudflare Workers)

هذا المسار لا يحتاج ترقية Firebase إلى Blaze ولا يستخدم Firebase Cloud Functions. التطبيق يحتفظ بتسجيل الدخول عبر Firebase، بينما يتحقق خادم Cloudflare من Firebase ID token ويصدر رمز LiveKit قصير العمر.

## ما تم تجهيزه في التطبيق

- شاشة مكالمات صوتية أو صوت وفيديو من الأقسام.
- رمز غرفة مشترك حتى يدخل الأصدقاء الغرفة نفسها.
- تشغيل/كتم المايكروفون وتشغيل/إيقاف الكاميرا وإنهاء المكالمة.
- التحقق من Firebase ID token على الخادم قبل إصدار LiveKit JWT.
- حفظ رابط خادم إصدار الرموز محلياً داخل التطبيق.
- عدم وضع LiveKit API Secret داخل التطبيق أو GitHub.

## نشر خادم الرموز من Termux

افتح Termux، وأنت داخل مجلد المستودع:

```bash
cd ~/future-youth-forum
git pull origin feature/v4-complete-profile-stats
cd workers/livekit-token
npm install -g wrangler
wrangler login
```

سيُفتح تسجيل Cloudflare. أنشئ حساباً مجانياً إذا لم يكن لديك حساب، ثم وافق على ربط Wrangler.

أدخل المفتاحين في مطالبة Termux فقط:

```bash
wrangler secret put LIVEKIT_API_KEY
wrangler secret put LIVEKIT_API_SECRET
```

- `LIVEKIT_API_KEY`: معرّف API Key من LiveKit.
- `LIVEKIT_API_SECRET`: السر الذي يظهر عند إنشاء المفتاح في LiveKit. لا تلصقه في المحادثة أو في ملف داخل المستودع.

انشر العامل:

```bash
wrangler deploy
```

سيطبع Cloudflare رابطاً شبيهاً بـ:

`https://future-youth-forum-livekit-token.<account>.workers.dev`

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
