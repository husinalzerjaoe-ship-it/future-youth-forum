# تشغيل خدمات ملتقى الأنمي

هذا الدليل مهم لأن رفع الصور والتصويتات والفعاليات تعتمد على قواعد وخدمات الخادم، وليس على ملف APK وحده.

## 1) Firebase Firestore Rules
1. افتح Firebase Console للمشروع الصحيح.
2. ادخل إلى Firestore Database ثم Rules.
3. استبدل القواعد بمحتوى ملف `firestore.rules` الموجود في هذا الفرع كاملاً.
4. اضغط Publish وانتظر نجاح النشر.

هذه القواعد تشمل المنشورات والتعليقات والإعجابات، المحادثة العامة والخاصة، الغرف الإقليمية، الملفات الشخصية، الستوريات، الشعر والاقتباسات، التصويتات، الفعاليات، وقائمة مشاهدة الأنمي.

## 2) Supabase Storage
1. افتح مشروع Supabase المرتبط بالتطبيق.
2. افتح SQL Editor.
3. شغّل ملف `supabase_public_chat_storage.sql` كاملاً.
4. تأكد أن bucket باسم `forum-media` موجود وأنه Public للقراءة، والرفع محمي بمجلد UID الخاص بصاحب الحساب.

## 3) Firebase Cloud Functions
من جذر المشروع نفّذ:
```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```
يجب تسجيل الدخول إلى Firebase CLI واختيار المشروع الصحيح أولاً. النشر يحتاج خطة Firebase تسمح بتشغيل Cloud Functions.
الدالة `ensureSupabaseAuthenticatedRole` تضيف مطالبة `role=authenticated` للحساب الحالي فقط، حتى تتمكن حسابات المستخدمين القديمة من رفع ملفاتها إلى Supabase.

## 4) Supabase Third-party Auth
في إعدادات Supabase Authentication، أضف Firebase كمزود Third-party Auth وتأكد أن التحقق من Firebase ID tokens مفعّل. رمز Firebase يجب أن يحتوي على `role=authenticated`.

## 5) اختبارات بعد النشر
- سجّل الدخول بحساب قديم، ثم ارفع صورة ملف شخصي وصورة في الشات وصورة خلفية أنمي.
- جرّب إرسال صورة في محادثة خاصة وغرفة دولة.
- جرّب نشر ستوري صورة وفيديو MP4 صغير.
- جرّب إنشاء تصويت من حساب عضو والتصويت مرة واحدة، ثم تحقق أن التصويت الثاني مرفوض.
- جرّب إنشاء فعالية بحساب المؤسس والتسجيل فيها بحساب عضو.
- إذا فشل رفع صورة، اقرأ رسالة الخطأ داخل التطبيق؛ ستحدد إن كانت المشكلة من Cloud Functions أو Supabase Storage أو حجم/نوع الملف.

## ملاحظات
- لا تضع مفاتيح Admin أو Service Role داخل التطبيق.
- لا ترفع صور أنمي محمية دون إذن؛ تبقى الخلفيات الجديدة معلقة حتى مراجعة الحقوق.
- APK وحده لا ينشر Firestore Rules ولا Supabase SQL ولا Cloud Functions.
