class TeamModel {
  final String id;
  final String name;
  final int playersCount;
  final int coachesCount;

  TeamModel({
    required this.id,
    required this.name,
    required this.playersCount,
    required this.coachesCount,
  });

  factory TeamModel.fromMap(String id, Map<String, dynamic> data) {
    return TeamModel(
      id: id,
      name: data['name'] ?? '',
      playersCount: data['playersCount'] ?? 0,
      coachesCount: data['coachesCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'playersCount': playersCount,
      'coachesCount': coachesCount,
    };
  }
}
