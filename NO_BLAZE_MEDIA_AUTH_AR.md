# إصلاح رفع الوسائط بدون نشر Cloud Functions مدفوعة

**تحديث:** لم يعد مسار الرفع يعتمد على `role=authenticated` الإضافي. شغّل نسخة SQL المحدّثة من `supabase_public_chat_storage.sql`؛ فهي تسمح بدور قاعدة البيانات `anon` فقط مع التحقق الصارم من Firebase issuer وaudience وUID ومجلد المستخدم. لا تستخدم سياسات كتابة عامة ولا مفاتيح service-role داخل التطبيق.

يستخدم التطبيق Firebase Authentication لتسجيل الدخول وSupabase Storage لحفظ الصور والستوريات والفويس. سياسات التخزين تتطلب أن يحتوي Firebase ID token على claim باسم `role=authenticated`.

## لماذا فشل الرفع؟
نشر قواعد Firestore وSQL وحدهما لا يضيفان هذا الـclaim إلى حسابات Firebase القديمة. نشر Cloud Functions يحتاج إعداد فوترة Blaze، لذلك لا نعتمد عليه لهذا الإصلاح.

## الحسابات الحالية
لا يلزم تشغيل سكربت Firebase Admin لمنح claim بعد تحديث SQL. سجّل الخروج والدخول بعد إعداد Firebase Third-party Auth في Supabase.
1. افتح مشروع Supabase ثم Authentication → Third-Party Auth.
2. تأكد أن Firebase مفعّل للمشروع `futureyouth-69f8a`.
3. شغّل SQL المحدّث من `supabase_public_chat_storage.sql`.
4. سجّل الخروج والدخول في التطبيق، ثم جرّب رفع صورة أو ستوري.

## الحسابات الجديدة
من دون Cloud Functions أو Firebase Identity Platform blocking triggers، لا يمكن إضافة claim تلقائياً لكل حساب جديد من تطبيق الهاتف بأمان. عند إضافة حسابات جديدة، أعد تشغيل السكربت أعلاه. لا نستخدم سياسة Storage عامة للكتابة ولا نضع مفتاح service-role داخل التطبيق.

## غرف مشاهدة يوتيوب
أضيفت قواعد Firestore لمجموعة `watchRooms` والمشاركين ورسائل الدردشة داخل الغرفة. يجب نشر `firestore.rules` بعد دمج هذا التغيير حتى تعمل المحادثة الجماعية.
