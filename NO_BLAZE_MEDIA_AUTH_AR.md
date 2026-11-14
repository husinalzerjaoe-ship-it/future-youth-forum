# إصلاح رفع الوسائط بدون نشر Cloud Functions مدفوعة

يستخدم التطبيق Firebase Authentication لتسجيل الدخول وSupabase Storage لحفظ الصور والستوريات والفويس. سياسات التخزين تتطلب أن يحتوي Firebase ID token على claim باسم `role=authenticated`.

## لماذا فشل الرفع؟
نشر قواعد Firestore وSQL وحدهما لا يضيفان هذا الـclaim إلى حسابات Firebase القديمة. نشر Cloud Functions يحتاج إعداد فوترة Blaze، لذلك لا نعتمد عليه لهذا الإصلاح.

## منح الصلاحية للحسابات الحالية من Cloud Shell (بدون Blaze)
1. افتح Cloud Shell للمشروع `futureyouth-69f8a`.
2. حدّث نسخة المستودع إلى الفرع `fix/media-auth-no-blaze-and-feature-entrypoints`.
3. من مجلد المشروع نفّذ:

```bash
npm --prefix functions install
gcloud auth application-default login
node functions/scripts/set_existing_users_role.js
```

إذا طلب تسجيل الدخول، أكمل بحساب Google الذي يملك صلاحية Firebase Authentication Admin للمشروع. لا ترفع Service Account JSON أو أي مفتاح خاص إلى GitHub ولا ترسله في المحادثة.

بعد ظهور `Updated N Firebase users with role=authenticated.` سجّل الخروج من التطبيق ثم ادخل من جديد؛ بعدها جرّب رفع صورة أو ستوري.

## الحسابات الجديدة
من دون Cloud Functions أو Firebase Identity Platform blocking triggers، لا يمكن إضافة claim تلقائياً لكل حساب جديد من تطبيق الهاتف بأمان. عند إضافة حسابات جديدة، أعد تشغيل السكربت أعلاه. لا نستخدم سياسة Storage عامة للكتابة ولا نضع مفتاح service-role داخل التطبيق.

## غرف مشاهدة يوتيوب
أضيفت قواعد Firestore لمجموعة `watchRooms` والمشاركين ورسائل الدردشة داخل الغرفة. يجب نشر `firestore.rules` بعد دمج هذا التغيير حتى تعمل المحادثة الجماعية.
