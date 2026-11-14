# إعداد ربط Firebase Auth مع Supabase Storage

## لماذا هذا الربط مطلوب؟
التطبيق يسجل دخول المستخدمين عبر Firebase Authentication، ويرفع صور الدردشة إلى Supabase Storage. لذلك يرسل التطبيق Firebase ID token إلى Supabase. سياسة التخزين تستخدم claim `sub` كنص لأن Firebase UID ليس مضموناً أن يكون UUID.

## إعداد Supabase مرة واحدة
1. افتح مشروع Supabase: `xwfzdiftlzrjsprnbwpf`.
2. اذهب إلى **Authentication → Sign In / Providers → Third-Party Auth**.
3. أضف Firebase كمزود Third-party Auth، واستخدم Firebase Project ID: `futureyouth-69f8a`.
4. احفظ الإعداد، وتأكد أن Firebase Third-party Auth يظهر كمزوّد مفعّل للمشروع الصحيح.
5. افتح **SQL Editor** وشغّل محتوى الملف `supabase_public_chat_storage.sql` كاملاً.
6. تأكد أن إعداد Firebase في Supabase يستخدم Project ID `futureyouth-69f8a` نفسه، وليس اسم التطبيق أو رابط Firebase Console.

الـbucket `forum-media` مضبوط كـPublic لأن الصور والستوريات والوسائط العامة تُعرض عبر public URL. لا ترفع إليه ملفات خاصة أو مستندات شخصية. حد الرفع 100MB، وتُقيد الأنواع المسموحة في SQL.

## تفعيل claim للمستخدمين
Supabase يحتاج claim باسم `role: authenticated` داخل Firebase ID token حتى يعامل المستخدم كـauthenticated. أُضيفت Cloud Function في `functions/index.js` للحسابات الجديدة.

من مجلد المشروع، بعد تسجيل الدخول إلى Firebase CLI واختيار المشروع الصحيح:

```bash
firebase use futureyouth-69f8a
firebase deploy --only functions,firestore:rules
```

قد تتطلب Cloud Functions تفعيل خطة Blaze والفوترة. لا تضع Service Account JSON أو مفاتيح Admin داخل GitHub.

بعد إضافة دعم الرسائل الصوتية في الدردشة العامة والخاصة وغرف الدول والغرف الخاصة، تأكد أن نشر `firestore.rules` تم أيضاً؛ وإلا قد تظهر رسائل `permission-denied` عند إرسال الفويس أو الصور داخل بعض الغرف.

### الحسابات الموجودة مسبقاً
نفّذ سكربت التحديث مرة واحدة من جهاز موثوق لديه Firebase Admin credentials:

```bash
cd functions
npm install
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json node scripts/set_existing_users_role.js
```

استبدل المسار بمكان ملف Service Account الذي نزلته من Firebase Console، ولا ترفعه إلى المستودع. السكربت يحافظ على custom claims الحالية ويضيف role فقط.

بعد منح claim للحساب، افتح التطبيق وسجّل خروجاً ثم دخولاً. التطبيق يستدعي الوظيفة الموثوقة للحسابات القديمة ويجدد Firebase ID token قبل الرفع. إذا ظهر خطأ `third-party auth` فالمشكلة في إعداد مزود Firebase داخل Supabase أو في نشر Cloud Function، وليست في اختيار الصورة.

## نظام نقاط التفاعل والترتيب الأسبوعي
أُضيفت Cloud Functions لاحتساب النقاط من الخادم حتى لا يستطيع العضو منح نفسه نقاطاً من التطبيق:
- الرسالة العامة: نقطتان مع زيادة عدّاد الرسائل.
- المنشور الجديد: 5 نقاط.
- الإعجاب الذي يصل إلى منشور العضو: نقطة واحدة (لا تُحتسب إعجابات العضو لنفسه).
- تُحفظ نقاط الأسبوع بمفتاح تاريخ يوم الاثنين UTC، ويعرض التطبيق ترتيب الأسبوع.

هذه الوظائف لا تعمل بمجرد رفع الكود إلى GitHub. بعد مراجعة المشروع وتسجيل الدخول إلى Firebase CLI، نفّذ من مجلد المشروع:

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

قد تتطلب Cloud Functions خطة Blaze والفوترة. لا تمنح نقاطاً يدوياً من واجهة العميل؛ المصدر الموثوق هو أحداث Firestore التي تعالجها الوظائف.

## بناء APK
كل push إلى main يشغّل GitHub Actions لتحليل Flutter وبناء APK. ويمكن تشغيله يدوياً من **Actions → Flutter quality check and Android APK → Run workflow**. بعد نجاحه، افتح workflow run ونزّل artifact باسم `future-youth-forum-release-apk`.

## ملاحظات مهمة
- إضافة الملفات إلى GitHub لا تعني أن Cloud Function أو SQL نُشرا تلقائياً؛ نفّذ الخطوات أعلاه في حسابات Firebase وSupabase.
- سجل العضوية الحالي يدعم منح العضوية من المؤسس فقط؛ تحصيل اشتراك 1 دولار يحتاج بوابة دفع متاحة في بلد التشغيل والتحقق من webhooks على خادم موثوق. لا توجد عملية تحصيل أموال فعلية مضافة بعد.
- حظر الجهاز الحقيقي لا يُنفذ عبر IMEI أو الرقم التسلسلي. يحتاج معرف تثبيت خاص بالتطبيق مع تحقق backend وApp Check.
