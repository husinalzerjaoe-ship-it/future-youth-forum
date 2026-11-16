# مساعد المستقبل + بوت تيليجرام — دليل الربط

هذا الدليل يربط واجهة Flutter في `lib/ai_assistant.dart` وبوت تيليجرام بمسار Gemini واحد عبر n8n.

## حالة التطبيق حالياً

- تمت إضافة صفحة «مساعد المستقبل» إلى قائمة الخدمات.
- سجل المحادثة يُحفظ محلياً على جهاز المستخدم.
- التطبيق يرسل إلى Webhook: `message`, `history`, `sessionId`, `source`.
- يرسل التطبيق Firebase ID token في ترويسة `Authorization: Bearer ...`.
- رابط Webhook غير مضبوط بعد؛ لذلك تظهر رسالة توضح أن الربط لم يكتمل. لا يوجد ادعاء بأن المساعد يعمل قبل ضبط الخادم.

## مخطط Workflow المقترح

1. **Webhook (App)**: استقبال POST من Flutter على مسار مثل `future-youth-ai-chat`.
2. **Telegram Trigger**: استقبال الرسائل النصية من البوت.
3. **Edit Fields / Set لكل مدخل**: توحيد البيانات إلى:
   - `source`: app أو telegram
   - `message`: نص المستخدم
   - `sessionId`: معرّف جلسة مستقل
   - `chatId`: مطلوب لمسار تيليجرام فقط
4. **تحقق وحماية لمسار التطبيق**: التحقق من Firebase ID token على الخادم قبل تمرير الطلب إلى Gemini. ارفض الطلبات غير الموثقة، وحدد معدل الطلبات وحجم النص. لا تعتمد على وجود UID في جسم الطلب وحده.
5. **AI Agent / Basic LLM Chain**: وصّل Google Gemini Chat Model، واستخدم تعليمات النظام:
   - أنت مساعد ملتقى شباب المستقبل.
   - أجب بالعربية الواضحة، وافهم اللهجة العراقية.
   - كن مشجعاً ومحترماً ومناسباً للأعمار المختلفة.
   - لا تطلب كلمات مرور أو رموز تحقق أو بيانات شخصية حساسة.
   - لا تدّعِ أنك نفذت إجراءً داخل التطبيق إذا لم تنفذه فعلاً.
6. **ذاكرة المحادثة**: استخدم مفتاح جلسة مستقل لكل مستخدم في التطبيق ولكل محادثة تيليجرام. لا تخلط جلسات الأعضاء.
7. **IF حسب source**:
   - app: أرجع JSON عبر Respond to Webhook بالشكل `{"reply":"نص الإجابة"}`.
   - telegram: استخدم Telegram Send Message مع `chatId` القادم من Telegram Trigger ونص الإجابة.
8. اختبر الفرعين برسائل قصيرة، وتأكد من أن رد التطبيق JSON وليس صفحة HTML.

## بيانات الاعتماد

- أنشئ Telegram bot من BotFather واحتفظ بالـ Bot Token داخل Credentials في n8n فقط.
- أنشئ Gemini API key من Google AI Studio واحفظه داخل Google Gemini Credentials في n8n فقط.
- لا ترسل هذه الرموز في محادثة ChatGPT أو تضعها في Flutter أو GitHub.
- لا تفعّل Webhook العام للتطبيق قبل إضافة التحقق من Firebase ID token وحدود الاستخدام.

## ربط التطبيق بعد نشر Workflow

بعد نشر Webhook واختباره، ضع عنوان Production URL في ثابت `futureAiWebhookUrl` في `lib/ai_assistant.dart`، أو مرره عبر إعداد بناء آمن. عنوان Webhook ليس بديلاً عن التحقق من هوية المستخدم؛ يجب أن يبقى التحقق داخل n8n/الخادم.

## ملاحظات الكلفة والخصوصية

- Google Gemini API يوفّر مستوى مجانياً لبعض النماذج مع حدود استخدام تتغير حسب النموذج والمشروع؛ راجع صفحة الأسعار وحدود الاستخدام قبل فتح البوت للجميع.
- في مستوى Gemini المجاني، قد تُستخدم البيانات لتحسين منتجات Google وفق الشروط المعروضة في صفحة الأسعار. لا ترسل معلومات خاصة أو أسرار.
- استضافة n8n نفسها قد تكون مجانية ذاتياً أو مدفوعة حسب مزود الاستضافة. لا تفترض أن n8n Cloud مجاني دائماً.
- ابدأ باختبار خاص ومحدود، ثم وسّع الوصول بعد تفعيل الحماية وحدود الاستخدام.

## روابط الوثائق

- n8n Telegram Trigger: https://docs.n8n.io/integrations/builtin/trigger-nodes/n8n-nodes-base.telegramtrigger/
- n8n Google Gemini Chat Model: https://docs.n8n.io/integrations/builtin/cluster-nodes/sub-nodes/n8n-nodes-langchain.lmchatgooglegemini/
- Google Gemini API pricing: https://ai.google.dev/gemini-api/docs/pricing
- Google Gemini API rate limits: https://ai.google.dev/gemini-api/docs/rate-limits
