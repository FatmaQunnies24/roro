import '../model/assessment_model.dart';

class StressCalculator {
  /// حساب مستوى التوتر + أسباب محتملة + نصائح بناءً على المدخلات.
  /// عند وجود مدة مراقبة: النتائج تُحسب حسب المعدل بالنسبة للوقت (ضغطات/دقيقة، صرخات/دقيقة، كلمات/دقيقة).
  static Map<String, dynamic> calculateStress(AssessmentModel assessment) {
    double score = 0.0;
    final List<String> reasons = [];
    final List<String> tips = [];

    final bool hasDuration = assessment.monitoringDurationSeconds > 0;
    final double durationMinutes = hasDuration
        ? (assessment.monitoringDurationSeconds / 60.0).clamp(0.1, 1440.0) // من 0.1 دقيقة حتى 24 ساعة
        : 1.0;

    // 1. عدد ساعات اللعب
    if (assessment.playHoursPerDay >= 8) {
      score += 60;
      reasons.add('وقت لعب طويل جداً (${assessment.playHoursPerDay.toStringAsFixed(1)} ساعة)');
      tips.add('قلّل وقت اللعب إلى ساعتين أو أقل يومياً');
    } else if (assessment.playHoursPerDay >= 6) {
      score += 45;
      reasons.add('وقت لعب طويل (${assessment.playHoursPerDay.toStringAsFixed(1)} ساعة)');
      tips.add('حدّد وقت لعب ثابت واتّبع جدولاً يومياً');
    } else if (assessment.playHoursPerDay >= 4) {
      score += 30;
      reasons.add('وقت لعب متوسط (${assessment.playHoursPerDay.toStringAsFixed(1)} ساعة)');
    } else if (assessment.playHoursPerDay >= 2) {
      score += 15;
    }

    // 2. نوع الألعاب
    if (assessment.gameType == 'تنافسية') {
      score += 20;
      reasons.add('ألعاب تنافسية تزيد الإثارة والتوتر');
      tips.add('جرّب ألعاباً هادئة أو تعاونية بين الحين والآخر');
    } else if (assessment.gameType == 'هادئة') {
      score += 5;
    }

    // 3. وقت اللعب
    if (assessment.playTime == 'ليل') {
      score += 15;
      reasons.add('اللعب ليلاً يؤثر على النوم والراحة');
      tips.add('تجنّب اللعب قبل النوم بساعة على الأقل');
    } else if (assessment.playTime == 'نهار') {
      score += 5;
    }

    // 4. اللعب الفردي أو الجماعي
    if (assessment.playMode == 'فردي') {
      score += 10;
      reasons.add('اللعب الفردي قد يزيد العزلة أو التركيز المفرط');
      tips.add('شجّع اللعب الجماعي أو المشاركة مع الأصدقاء أحياناً');
    } else if (assessment.playMode == 'جماعي') {
      score += 5;
    }

    // 5. المؤشر الذاتي للضغط
    score += assessment.stressLevel * 2;
    if (assessment.stressLevel >= 6) {
      reasons.add('الشعور الذاتي بالضغط مرتفع');
      tips.add('خذ استراحات قصيرة وتنفّس بعمق أثناء اللعب');
    }

    // 6. عدد الضغطات — منطقي بالنسبة للوقت (معدل الضغطات في الدقيقة)
    if (hasDuration) {
      final tapsPerMin = assessment.tapCount / durationMinutes;
      if (tapsPerMin >= 40) {
        score += 15;
        reasons.add('معدل ضغطات عالٍ جداً (${tapsPerMin.toStringAsFixed(0)} ضغطة/دقيقة خلال ${durationMinutes.toStringAsFixed(0)} دقيقة) — نشاط مكثّف');
        tips.add('قلّل مدة الجلسة أو اختر ألعاباً أقل سرعة');
      } else if (tapsPerMin >= 25) {
        score += 10;
        reasons.add('معدل ضغطات مرتفع (${tapsPerMin.toStringAsFixed(0)} ضغطة/دقيقة)');
      } else if (tapsPerMin >= 10) {
        score += 5;
      }
    } else {
      if (assessment.tapCount > 500) {
        score += 15;
        reasons.add('عدد ضغطات عالٍ جداً (${assessment.tapCount}) — نشاط مكثّف');
        tips.add('قلّل مدة الجلسة أو اختر ألعاباً أقل سرعة');
      } else if (assessment.tapCount >= 300) {
        score += 10;
        reasons.add('عدد ضغطات مرتفع (${assessment.tapCount})');
      } else if (assessment.tapCount >= 100) {
        score += 5;
      }
    }

    // 7. متوسط مستوى الصوت
    if (assessment.averageSoundLevel > 70) {
      score += 15;
      reasons.add('مستوى الصوت مرتفع — احتمال توتر أو إثارة');
      tips.add('خَفّض صوت الجهاز واطلب من الطفل تخفيف الصراخ');
    } else if (assessment.averageSoundLevel >= 50) {
      score += 10;
    } else if (assessment.averageSoundLevel >= 30) {
      score += 5;
    }

    // 8. عدد الصرخات — منطقي بالنسبة للوقت (معدل الصرخات في الدقيقة)
    if (hasDuration) {
      final screamsPerMin = assessment.screamCount / durationMinutes;
      if (screamsPerMin >= 1.0) {
        score += 20;
        reasons.add('معدل صرخات مرتفع (${assessment.screamCount} صرخة خلال ${durationMinutes.toStringAsFixed(0)} دقيقة — ${screamsPerMin.toStringAsFixed(1)}/دقيقة) — قد يدل على عصبية أو إحباط');
        tips.add('تحدّث مع الطفل عن الغضب وعلّمهم أخذ نفس قبل الصراخ');
      } else if (screamsPerMin >= 0.3) {
        score += 12;
        reasons.add('وجود صرخات (${assessment.screamCount} خلال ${durationMinutes.toStringAsFixed(0)} دقيقة) — انتبه للحالة النفسية');
        tips.add('راقب متى يصرخ الطفل ووجّهه لأسلوب هادئ');
      } else if (assessment.screamCount >= 1) {
        score += 5;
        reasons.add('صرخة واحدة على الأقل — راقب إذا تكررت');
      }
    } else {
      score += assessment.screamCount * 5;
      if (assessment.screamCount >= 5) {
        reasons.add('عدد صرخات كثير (${assessment.screamCount}) — قد يدل على عصبية أو إحباط');
        tips.add('تحدّث مع الطفل عن الغضب وعلّمهم أخذ نفس قبل الصراخ');
      } else if (assessment.screamCount >= 2) {
        reasons.add('وجود صرخات (${assessment.screamCount}) — انتبه للحالة النفسية');
        tips.add('راقب متى يصرخ الطفل ووجّهه لأسلوب هادئ');
      }
    }

    // 9. الكلمات السيئة — منطقي بالنسبة للوقت (معدل في الدقيقة)
    if (hasDuration) {
      final badWordsPerMin = assessment.badWordsCount / durationMinutes;
      if (badWordsPerMin >= 0.5 || assessment.badWordsCount >= 3) {
        score += 15;
        reasons.add('كلمات سيئة متكررة (${assessment.badWordsCount} خلال ${durationMinutes.toStringAsFixed(0)} دقيقة) — قد تدل على توتر أو تقليد سلبي');
        tips.add('وضح للطفل أن هذه الكلمات غير مقبولة وقدم بدائل للتعبير عن الغضب');
      } else if (assessment.badWordsCount >= 1) {
        score += 8;
        reasons.add('استخدام كلمات سيئة (${assessment.badWordsCount}) — راقب المصدر (أصدقاء، ألعاب)');
        tips.add('ناقش مع الطفل لماذا نبتعد عن هذه الكلمات');
      }
    } else {
      score += assessment.badWordsCount * 3;
      if (assessment.badWordsCount >= 5) {
        reasons.add('كلمات سيئة متكررة (${assessment.badWordsCount}) — قد تدل على توتر أو تقليد سلبي');
        tips.add('وضح للطفل أن هذه الكلمات غير مقبولة وقدم بدائل للتعبير عن الغضب');
      } else if (assessment.badWordsCount >= 1) {
        reasons.add('استخدام كلمات سيئة (${assessment.badWordsCount}) — راقب المصدر (أصدقاء، ألعاب)');
        tips.add('ناقش مع الطفل لماذا نبتعد عن هذه الكلمات');
      }
    }

    // تحديد مستوى التوتر
    String level;
    if (score >= 70) {
      level = 'مرتفع';
      if (reasons.isEmpty) reasons.add('مجموع المؤشرات يشير إلى توتر أو عصبية محتملة');
      tips.add('استشر مختصاً إذا استمرت العلامات أو زادت');
    } else if (score >= 40) {
      level = 'متوسط';
      if (reasons.isEmpty) reasons.add('بعض المؤشرات تحتاج انتباهاً');
    } else {
      level = 'منخفض';
      if (reasons.isEmpty) reasons.add('الوضع العام جيد');
      tips.add('استمر بالمراقبة المعتدلة ودعم الطفل');
    }

    return {
      'stressScore': score.clamp(0.0, 100.0),
      'predictedStressLevel': level,
      'reasons': reasons.join(' • '),
      'tips': tips.join(' • '),
    };
  }
}

