class ExerciseModel {
  final String id;
  final String title;
  final String description;
  final String targetPosition;
  final List<String> targetAttributes;

  ExerciseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.targetPosition,
    required this.targetAttributes,
  });

  factory ExerciseModel.fromMap(String id, Map<String, dynamic> data) {
    return ExerciseModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      targetPosition: data['targetPosition'] ?? '',
      targetAttributes: List<String>.from(data['targetAttributes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'targetPosition': targetPosition,
      'targetAttributes': targetAttributes,
    };
  }
}
