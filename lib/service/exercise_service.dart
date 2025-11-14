import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/exercise_model.dart';

class ExerciseService {
  final CollectionReference<Map<String, dynamic>> _exercisesRef =
      FirebaseFirestore.instance.collection('exercises');

  /// إضافة تمرين جديد
  Future<void> addExercise(ExerciseModel exercise) async {
    await _exercisesRef.add(exercise.toMap());
  }

  /// جلب جميع التمارين
  Stream<List<ExerciseModel>> getAllExercises() {
    return _exercisesRef.snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ExerciseModel.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  /// جلب التمارين حسب نوع اللاعب
  Stream<List<ExerciseModel>> getExercisesByPosition(String positionType) {
    return _exercisesRef
        .where('targetPosition', isEqualTo: positionType)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ExerciseModel.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  /// جلب التمارين حسب نوع اللاعب ودوره في الفريق
  Stream<List<ExerciseModel>> getExercisesByPositionAndRole(
    String positionType,
    String roleInTeam,
  ) {
    return _exercisesRef
        .where('targetPosition', isEqualTo: positionType)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ExerciseModel.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .where((exercise) =>
                  exercise.roleInTeam == 'all' ||
                  exercise.roleInTeam == roleInTeam)
              .toList(),
        );
  }

  /// جلب التمارين المناسبة للاعب حسب مواصفاته
  Future<List<ExerciseModel>> getRecommendedExercisesForPlayer({
    required String positionType,
    required String roleInTeam,
    required double speed,
    required double shotPower,
    required double stamina,
    required double bodyStrength,
    required double balance,
    required double effortIndex,
  }) async {
    // جلب جميع التمارين المناسبة
    final snapshot = await _exercisesRef
        .where('targetPosition', isEqualTo: positionType)
        .get();

    List<ExerciseModel> exercises = snapshot.docs
        .map(
          (doc) => ExerciseModel.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .where((exercise) =>
            exercise.roleInTeam == 'all' ||
            exercise.roleInTeam == roleInTeam)
        .toList();

    // ترتيب التمارين حسب المواصفات التي تحتاج تحسين
    exercises.sort((a, b) {
      // تحديد المواصفات الأضعف التي تحتاج تحسين
      Map<String, double> metrics = {
        'speed': speed,
        'shotPower': shotPower,
        'stamina': stamina,
        'bodyStrength': bodyStrength,
        'balance': balance,
      };

      // العثور على أدنى مواصفة
      String weakestMetric = metrics.entries
          .reduce((a, b) => a.value < b.value ? a : b)
          .key;

      // ترتيب التمارين حسب ما إذا كانت تستهدف المواصفة الأضعف
      bool aTargetsWeakest = a.targetAttributes.contains(weakestMetric);
      bool bTargetsWeakest = b.targetAttributes.contains(weakestMetric);

      if (aTargetsWeakest && !bTargetsWeakest) return -1;
      if (!aTargetsWeakest && bTargetsWeakest) return 1;
      return 0;
    });

    return exercises;
  }

  /// تهيئة التمارين الافتراضية في قاعدة البيانات
  Future<void> initializeDefaultExercises() async {
    final defaultExercises = [
      // تمارين للهجوم
      ExerciseModel(
        id: 'ex1',
        title: 'تمرين السرعة والانطلاق',
        description:
            'ركض سريع لمسافة 50 متر مع استراحة 30 ثانية، كرر 10 مرات',
        targetPosition: 'forward',
        roleInTeam: 'all',
        targetAttributes: ['speed', 'stamina'],
        durationMinutes: 30,
        frequencyPerWeek: 4,
        bestTimeOfDay: 'evening',
        restDaysBetween: 1,
      ),
      ExerciseModel(
        id: 'ex2',
        title: 'تمرين قوة الضربة',
        description: 'ضربات على المرمى من مسافات مختلفة، 50 ضربة',
        targetPosition: 'forward',
        roleInTeam: 'all',
        targetAttributes: ['shotPower', 'balance'],
        durationMinutes: 45,
        frequencyPerWeek: 3,
        bestTimeOfDay: 'afternoon',
        restDaysBetween: 1,
      ),
      // تمارين للدفاع
      ExerciseModel(
        id: 'ex3',
        title: 'تمرين قوة الجسم',
        description: 'تمرينات ضغط، قرفصاء، وسحب - 3 مجموعات × 15 تكرار',
        targetPosition: 'defender',
        roleInTeam: 'all',
        targetAttributes: ['bodyStrength', 'balance'],
        durationMinutes: 40,
        frequencyPerWeek: 4,
        bestTimeOfDay: 'morning',
        restDaysBetween: 1,
      ),
      ExerciseModel(
        id: 'ex4',
        title: 'تمرين الاتزان والمرونة',
        description: 'وقوف على قدم واحدة، تمارين مرونة، 20 دقيقة',
        targetPosition: 'defender',
        roleInTeam: 'all',
        targetAttributes: ['balance', 'bodyStrength'],
        durationMinutes: 20,
        frequencyPerWeek: 5,
        bestTimeOfDay: 'morning',
        restDaysBetween: 0,
      ),
      // تمارين للوسط
      ExerciseModel(
        id: 'ex5',
        title: 'تمرين التحمل',
        description: 'ركض طويل المسافة 5 كم بوتيرة متوسطة',
        targetPosition: 'midfield',
        roleInTeam: 'all',
        targetAttributes: ['stamina', 'speed'],
        durationMinutes: 35,
        frequencyPerWeek: 3,
        bestTimeOfDay: 'evening',
        restDaysBetween: 1,
      ),
      ExerciseModel(
        id: 'ex6',
        title: 'تمرين السرعة والتحمل',
        description: 'ركض متقطع: 2 دقيقة سريع، 1 دقيقة بطيء - 20 دقيقة',
        targetPosition: 'midfield',
        roleInTeam: 'all',
        targetAttributes: ['speed', 'stamina'],
        durationMinutes: 20,
        frequencyPerWeek: 4,
        bestTimeOfDay: 'evening',
        restDaysBetween: 1,
      ),
      // تمارين للحارس
      ExerciseModel(
        id: 'ex7',
        title: 'تمرين رد الفعل والاتزان',
        description: 'تمارين قفز وحركات سريعة، 30 دقيقة',
        targetPosition: 'goalkeeper',
        roleInTeam: 'all',
        targetAttributes: ['balance', 'speed'],
        durationMinutes: 30,
        frequencyPerWeek: 4,
        bestTimeOfDay: 'afternoon',
        restDaysBetween: 1,
      ),
      ExerciseModel(
        id: 'ex8',
        title: 'تمرين قوة الجسم للحارس',
        description: 'تمارين قوة خاصة بالحارس، 3 مجموعات',
        targetPosition: 'goalkeeper',
        roleInTeam: 'all',
        targetAttributes: ['bodyStrength', 'balance'],
        durationMinutes: 35,
        frequencyPerWeek: 3,
        bestTimeOfDay: 'morning',
        restDaysBetween: 1,
      ),
      // تمارين للاحتياطي
      ExerciseModel(
        id: 'ex9',
        title: 'تمرين شامل للاحتياطي',
        description: 'مزيج من تمارين السرعة والتحمل والقوة',
        targetPosition: 'substitute',
        roleInTeam: 'reserve',
        targetAttributes: ['speed', 'stamina', 'bodyStrength'],
        durationMinutes: 45,
        frequencyPerWeek: 5,
        bestTimeOfDay: 'evening',
        restDaysBetween: 0,
      ),
    ];

    // إضافة التمارين إلى قاعدة البيانات
    for (var exercise in defaultExercises) {
      await _exercisesRef.doc(exercise.id).set(exercise.toMap());
    }
  }
}

