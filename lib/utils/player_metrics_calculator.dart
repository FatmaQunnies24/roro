/// حاسبة مواصفات اللاعبين
/// تحتوي على معادلات حساب جميع المواصفات
class PlayerMetricsCalculator {
  /// حساب السرعة (كم/ساعة)
  /// المدخلات: المسافة المقطوعة (متر)، الوقت (ثانية)
  /// المعادلة: السرعة = (المسافة / الوقت) * 3.6
  static double calculateSpeed({
    required double distanceInMeters, // المسافة بالمتر
    required double timeInSeconds, // الوقت بالثانية
  }) {
    if (timeInSeconds <= 0) return 0;
    return (distanceInMeters / timeInSeconds) * 3.6; // تحويل من م/ث إلى كم/س
  }

  /// حساب قوة الضربة (نيوتن)
  /// المدخلات: كتلة الكرة (كجم)، سرعة الكرة بعد الضربة (م/ث)
  /// المعادلة: القوة = الكتلة * التسارع (حيث التسارع = السرعة / الوقت)
  /// أو يمكن استخدام: القوة = الكتلة * السرعة^2 / المسافة
  static double calculateShotPower({
    required double ballMass, // كتلة الكرة بالكيلوجرام (عادة 0.43 كجم)
    required double ballVelocity, // سرعة الكرة بعد الضربة (م/ث)
    double impactTime = 0.01, // وقت التأثير بالثانية (افتراضي 0.01 ثانية)
  }) {
    // القوة = الكتلة * (السرعة / وقت التأثير)
    return ballMass * (ballVelocity / impactTime);
  }

  /// حساب قدرة التحمل (نسبة مئوية)
  /// المدخلات: المسافة المقطوعة (متر)، الوقت الكلي (ثانية)، معدل ضربات القلب
  /// المعادلة: التحمل = (المسافة المقطوعة / الوقت) / (معدل ضربات القلب / 60) * 100
  /// أو معادلة أبسط: التحمل = (المسافة / الوقت) / السرعة القصوى المتوقعة * 100
  static double calculateStamina({
    required double distanceInMeters,
    required double timeInSeconds,
    required double maxHeartRate, // معدل ضربات القلب الأقصى
    required double currentHeartRate, // معدل ضربات القلب الحالي
    double maxExpectedDistance = 10000, // المسافة القصوى المتوقعة (10 كم)
  }) {
    if (timeInSeconds <= 0) return 0;
    
    // حساب نسبة التحمل بناءً على المسافة والوقت ومعدل ضربات القلب
    double distanceRatio = distanceInMeters / maxExpectedDistance;
    double heartRateRatio = 1 - ((currentHeartRate - 60) / (maxHeartRate - 60));
    
    // التحمل = متوسط نسبة المسافة ونسبة معدل ضربات القلب
    return ((distanceRatio * 0.6) + (heartRateRatio * 0.4)) * 100;
  }

  /// حساب معدل قوة الجسم (كجم)
  /// المدخلات: وزن الجسم (كجم)، عدد تمرينات الضغط، عدد تمرينات القرفصاء
  /// المعادلة: قوة الجسم = (وزن الجسم * 0.4) + (عدد الضغط * 2) + (عدد القرفصاء * 1.5)
  static double calculateBodyStrength({
    required double bodyWeight, // وزن الجسم بالكيلوجرام
    required int pushUps, // عدد تمرينات الضغط
    required int squats, // عدد تمرينات القرفصاء
    required int pullUps, // عدد تمرينات السحب
  }) {
    double baseStrength = bodyWeight * 0.4;
    double pushUpStrength = pushUps * 2.0;
    double squatStrength = squats * 1.5;
    double pullUpStrength = pullUps * 3.0;
    
    return baseStrength + pushUpStrength + squatStrength + pullUpStrength;
  }

  /// حساب الاتزان (نسبة مئوية)
  /// المدخلات: الوقت على قدم واحدة (ثانية)، عدد المرات التي فقد فيها الاتزان
  /// المعادلة: الاتزان = (الوقت على قدم واحدة / 60) * (1 - عدد مرات فقدان الاتزان / 10) * 100
  static double calculateBalance({
    required double singleLegStandTime, // الوقت على قدم واحدة بالثانية
    required int balanceLossCount, // عدد مرات فقدان الاتزان
    double maxStandTime = 60.0, // أقصى وقت متوقع (60 ثانية)
  }) {
    double timeRatio = (singleLegStandTime / maxStandTime).clamp(0.0, 1.0);
    double lossPenalty = (balanceLossCount / 10.0).clamp(0.0, 1.0);
    
    return (timeRatio * (1 - lossPenalty)) * 100;
  }

  /// حساب معدل الجهد (نسبة مئوية)
  /// المدخلات: عدد ساعات التدريب الأسبوعية، عدد التمارين المكتملة، عدد التمارين المطلوبة
  /// المعادلة: معدل الجهد = (عدد التمارين المكتملة / عدد التمارين المطلوبة) * (ساعات التدريب / 20) * 100
  static double calculateEffortIndex({
    required double weeklyTrainingHours, // عدد ساعات التدريب الأسبوعية
    required int completedExercises, // عدد التمارين المكتملة
    required int totalExercises, // عدد التمارين المطلوبة
    double maxWeeklyHours = 20.0, // أقصى ساعات تدريب أسبوعية متوقعة
  }) {
    if (totalExercises <= 0) return 0;
    
    double exerciseRatio = completedExercises / totalExercises;
    double hoursRatio = (weeklyTrainingHours / maxWeeklyHours).clamp(0.0, 1.0);
    
    return (exerciseRatio * 0.7 + hoursRatio * 0.3) * 100;
  }

  /// حساب النتيجة الإجمالية للاعب
  /// المعادلة: النتيجة = (السرعة * 0.2) + (قوة الضربة * 0.15) + (التحمل * 0.25) + 
  ///                    (قوة الجسم * 0.15) + (الاتزان * 0.15) + (معدل الجهد * 0.1)
  static double calculateOverallScore({
    required double speed, // السرعة (كم/س)
    required double shotPower, // قوة الضربة (نيوتن)
    required double stamina, // التحمل (نسبة مئوية)
    required double bodyStrength, // قوة الجسم (كجم)
    required double balance, // الاتزان (نسبة مئوية)
    required double effortIndex, // معدل الجهد (نسبة مئوية)
  }) {
    // تحويل السرعة وقوة الضربة إلى مقياس 0-100
    double normalizedSpeed = (speed / 30.0).clamp(0.0, 1.0) * 100; // 30 كم/س = 100%
    double normalizedShotPower = (shotPower / 5000.0).clamp(0.0, 1.0) * 100; // 5000 نيوتن = 100%
    double normalizedBodyStrength = (bodyStrength / 200.0).clamp(0.0, 1.0) * 100; // 200 كجم = 100%

    return (normalizedSpeed * 0.2) +
           (normalizedShotPower * 0.15) +
           (stamina * 0.25) +
           (normalizedBodyStrength * 0.15) +
           (balance * 0.15) +
           (effortIndex * 0.1);
  }

  /// تحليل أداء اللاعب وإرجاع نص وصف
  static String getPerformanceDescription(double overallScore) {
    if (overallScore >= 80) {
      return "أداء ممتاز! اللاعب في حالة جيدة جداً ويظهر تحسناً مستمراً.";
    } else if (overallScore >= 65) {
      return "أداء جيد. اللاعب يتحسن ولكن يحتاج إلى مزيد من التدريب في بعض المجالات.";
    } else if (overallScore >= 50) {
      return "أداء متوسط. اللاعب يحتاج إلى تدريب أكثر لتحسين أدائه.";
    } else if (overallScore >= 35) {
      return "أداء ضعيف. اللاعب يحتاج إلى تدريب مكثف لتحسين جميع الجوانب.";
    } else {
      return "أداء ضعيف جداً. يحتاج إلى برنامج تدريبي شامل ومكثف.";
    }
  }
}

