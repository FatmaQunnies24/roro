class ExerciseModel {
  final String id;
  final String title;
  final String description;
  final String targetPosition; // نوع اللاعب المستهدف
  final String roleInTeam; // أساسي أو احتياطي
  final List<String> targetAttributes; // المواصفات المستهدفة (سرعة، قوة، إلخ)
  final int durationMinutes; // مدة التمرين بالدقائق
  final int frequencyPerWeek; // عدد مرات التمرين في الأسبوع
  final String bestTimeOfDay; // أفضل وقت في اليوم (صباح، ظهر، مساء)
  final int restDaysBetween; // أيام الراحة بين التمارين

  ExerciseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.targetPosition,
    this.roleInTeam = 'all', // 'all', 'starter', 'reserve'
    required this.targetAttributes,
    required this.durationMinutes,
    required this.frequencyPerWeek,
    this.bestTimeOfDay = 'evening', // 'morning', 'afternoon', 'evening'
    this.restDaysBetween = 1,
  });

  factory ExerciseModel.fromMap(String id, Map<String, dynamic> data) {
    return ExerciseModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      targetPosition: data['targetPosition'] ?? '',
      roleInTeam: data['roleInTeam'] ?? 'all',
      targetAttributes: List<String>.from(data['targetAttributes'] ?? []),
      durationMinutes: data['durationMinutes'] ?? 30,
      frequencyPerWeek: data['frequencyPerWeek'] ?? 3,
      bestTimeOfDay: data['bestTimeOfDay'] ?? 'evening',
      restDaysBetween: data['restDaysBetween'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'targetPosition': targetPosition,
      'roleInTeam': roleInTeam,
      'targetAttributes': targetAttributes,
      'durationMinutes': durationMinutes,
      'frequencyPerWeek': frequencyPerWeek,
      'bestTimeOfDay': bestTimeOfDay,
      'restDaysBetween': restDaysBetween,
    };
  }
}
