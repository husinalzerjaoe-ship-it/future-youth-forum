# ربط Firebase Authentication مع Supabase Storage

## الإعداد المطلوب مرة واحدة

التطبيق يسجل دخول الأعضاء بواسطة Firebase Authentication، ويستخدم Supabase Storage لرفع صور الدردشة والملفات الصوتية. لذلك يجب أن يتعرف Supabase على رمز Firebase ID Token كمزوّد مصادقة خارجي.

1. افتح مشروع Supabase: https://supabase.com/dashboard/project/xwfzdiftlzrjsprnbwpf
2. اذهب إلى **Authentication → Sign In / Providers → Third-Party Auth**.
3. أضف **Firebase** كمزوّد خارجي، واكتب Project ID التالي حرفياً: `futureyouth-69f8a` (انتبه لحرف a الأخير).
4. احفظ إعدادات المزوّد.
5. افتح SQL Editor وشغّل محتوى الملف `supabase_public_chat_storage.sql` كاملاً.
6. تأكد أن Storage يحتوي Bucket باسم `forum-media` وأنه Public لعرض روابط الصور والصوت والفيديوهات العامة.

## ما الذي تسمح به السياسات؟

- قراءة الوسائط العامة من Bucket `forum-media`.
- رفع كل عضو إلى مجلده الخاص فقط.
- دعم مجلدات `public-chat`, `private-chat`, `regional-chat`, `profiles`, `stories`, `chat-backgrounds`, `anime-wallpapers`, و`shared-files`.
- التحقق من Firebase issuer وaudience وUID داخل JWT قبل قبول الرفع.
- لا تضع Service Account JSON أو Private Key أو مفاتيح Admin داخل المستودع أو داخل التطبيق.

**مهم:** رفع الصور والفويس لا يحتاج نشر Cloud Functions أو تفعيل خطة Blaze؛ التحقق الحالي يتم عبر Firebase Third-Party Auth وسياسات Storage. لا تشغّل أو تنشر Cloud Functions لهذا الغرض.

## بعد ضبط الإعداد

1. ثبّت أحدث APK بعد نجاح GitHub Actions.
2. سجّل الخروج من التطبيق ثم ادخل من جديد حتى يحصل التطبيق على رمز دخول حديث.
3. اختبر إرسال صورة وفويس في المحادثة العامة، ثم صورة وفويس في محادثة خاصة.
4. إذا فشل الرفع، أرسل نص الخطأ ورمز الخطأ فقط، ولا ترسل Firebase ID Token أو أي مفتاح خاص.

## ميزات أخرى لا تعتمد على هذا الربط

- نقاط التفاعل الأسبوعية وبعض المهام الآلية قد تعتمد على Cloud Functions منفصلة.
- لا توجد بوابة دفع فعلية للاشتراك الشهري حتى الآن؛ منح العضويات المجانية يتم من حساب المؤسس، أما تحصيل 1 دولار فيحتاج بوابة دفع وخادماً موثوقاً لمعالجة الإشعارات.
- قواعد Firestore الموجودة في `firestore.rules` يجب نشرها يدوياً من Firebase Console أو Firebase CLI؛ تحديث الملف في GitHub لا ينشر القواعد تلقائياً.
