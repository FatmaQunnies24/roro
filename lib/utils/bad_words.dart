/// قائمة كلمات سيئة للكشف عنها في الصوت (عربي + إنجليزي).
/// يمكنك إضافة أو حذف كلمات حسب الحاجة في الملف: lib/utils/bad_words.dart
const List<String> kBadWordsList = [
  'يلعن',
  'خرا',
  'خرة',
  'خراء',
  'خرى',
  'خري',
  'زق',
  'طيز',
  'كس',
  'شرموطة',
  'قحبة',
  'حيوان',
  'حيون',
  'حيان',
  'حيوانات',
  'كلب',
  'كلاب',
  'خنزير',
  'خنازير',
  'غبي',
  'حمار',
  'أحمق',
  'damn',
  'shit',
  'fuck',
  'ass',
  'bitch',
  'idiot',
  'stupid',
  // صيغ مُخفاة قد يخرجها التعرف على الصوت أو النظام (تحسب ككلمة سيئة)
  's****',
  's***',
  'f****',
  'f***',
  'a**',
  'b****',
];

/// يفحص النص ويُرجع خريطة: كل كلمة سيئة → عدد مرات ظهورها.
/// كل ظهور (بما فيها الصيغ المُخفاة مثل s****) = +1 للكاونت.
/// للتشخيص: إرجاع النص بعد التطبيع (لطباعته في الكونسول إن لزم)
String getNormalizedTextForDebug(String text) => _normalize(text);

Map<String, int> countBadWordsInText(String text) {
  if (text.isEmpty) return {};
  final Map<String, int> counts = {};
  final normalizedText = _normalize(text);
  // مطابقة أيضاً على النص بدون مسافات لالتقاط ما يرجعه المحرك متفرقاً مثل "خ ر ا"
  final normalizedNoSpaces = normalizedText.replaceAll(' ', '');
  for (final bad in kBadWordsList) {
    final normalizedBad = _normalize(bad);
    if (normalizedBad.isEmpty) continue;
    final pattern = RegExp(RegExp.escape(normalizedBad));
    final c1 = pattern.allMatches(normalizedText).length;
    final c2 = pattern.allMatches(normalizedNoSpaces).length;
    // نستخدم العدد الأكبر: إن رجع المحرك "خ ر ا" يطابق في normalizedNoSpaces فقط
    final c = c1 > c2 ? c1 : c2;
    if (c > 0) counts[bad] = (counts[bad] ?? 0) + c;
  }
  return counts;
}

/// توحيد النص لتحسين المطابقة: خرة=خرا، الحيوان=حيوان، إلخ
String _normalize(String s) {
  String t = s.trim().toLowerCase();
  t = t.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), ''); // تشكيل
  t = t.replaceAll('ة', 'ا'); // تاء مربوطة → ا
  t = t.replaceAll(RegExp(r'[أإآ]'), 'ا');
  t = t.replaceAll('ى', 'ي');
  t = t.replaceAll('ئ', 'ي');
  t = t.replaceAll('ؤ', 'و');
  t = t.replaceAll('ء', 'ا'); // همزة → ا (خراء → خراا ثم نطابق خرا)
  t = t.replaceAll(RegExp(r'\s+'), ' ');
  t = t.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), ''); // أحرف عرض صفر
  t = t.replaceAll('•', '*').replaceAll('·', '*').replaceAll('＊', '*'); // توحيد النجمة
  return t;
}

/// يبني نص التقرير للعرض في الريبورت: "كلمة (3)، كلمة (1)"
String buildBadWordsReport(Map<String, int> counts) {
  if (counts.isEmpty) return '';
  return counts.entries
      .map((e) => '${e.key} (${e.value})')
      .join('، ');
}
