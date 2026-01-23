import '../model/assessment_model.dart';

class StressCalculator {
  /// حساب مستوى التوتر بناءً على المدخلات
  static Map<String, dynamic> calculateStress(AssessmentModel assessment) {
    double score = 0.0;

    // 1. عدد ساعات اللعب (كلما زادت الساعات، زاد التوتر)
    // 0-2 ساعات: 0 نقطة، 2-4: 15 نقطة، 4-6: 30 نقطة، 6-8: 45 نقطة، 8+: 60 نقطة
    if (assessment.playHoursPerDay >= 8) {
      score += 60;
    } else if (assessment.playHoursPerDay >= 6) {
      score += 45;
    } else if (assessment.playHoursPerDay >= 4) {
      score += 30;
    } else if (assessment.playHoursPerDay >= 2) {
      score += 15;
    }

    // 2. نوع الألعاب (تنافسية تزيد التوتر أكثر من الهادئة)
    if (assessment.gameType == 'تنافسية') {
      score += 20;
    } else if (assessment.gameType == 'هادئة') {
      score += 5;
    }

    // 3. وقت اللعب (الليل يزيد التوتر أكثر)
    if (assessment.playTime == 'ليل') {
      score += 15;
    } else if (assessment.playTime == 'نهار') {
      score += 5;
    }

    // 4. اللعب الفردي أو الجماعي (الفردي قد يزيد التوتر)
    if (assessment.playMode == 'فردي') {
      score += 10;
    } else if (assessment.playMode == 'جماعي') {
      score += 5;
    }

    // 5. المؤشر الذاتي للضغط (0-10) يضاف مباشرة مضروبًا في 2
    score += assessment.stressLevel * 2;

    // 6. عدد الضغطات (كلما زادت الضغطات، زاد التوتر)
    // أكثر من 500 ضغطة: 15 نقطة، 300-500: 10 نقطة، 100-300: 5 نقطة
    if (assessment.tapCount > 500) {
      score += 15;
    } else if (assessment.tapCount >= 300) {
      score += 10;
    } else if (assessment.tapCount >= 100) {
      score += 5;
    }

    // 7. متوسط مستوى الصوت (كلما زاد الصوت، زاد التوتر)
    // أكثر من 70%: 15 نقطة، 50-70%: 10 نقطة، 30-50%: 5 نقطة
    if (assessment.averageSoundLevel > 70) {
      score += 15;
    } else if (assessment.averageSoundLevel >= 50) {
      score += 10;
    } else if (assessment.averageSoundLevel >= 30) {
      score += 5;
    }

    // 8. عدد الصرخات (كل صرخة تضيف 5 نقاط)
    score += assessment.screamCount * 5;

    // تحديد مستوى التوتر
    String level;
    if (score >= 70) {
      level = 'مرتفع';
    } else if (score >= 40) {
      level = 'متوسط';
    } else {
      level = 'منخفض';
    }

    return {
      'stressScore': score.clamp(0.0, 100.0),
      'predictedStressLevel': level,
    };
  }
}

