class UserModel {
  final String id;
  final String name;
  final String role; // coach / player
  final String teamId;
  final String? playerId;

  UserModel({
    required this.id,
    required this.name,
    required this.role,
    required this.teamId,
    this.playerId,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      role: data['role'] ?? '',
      teamId: data['teamId'] ?? '',
      playerId: data['playerId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'teamId': teamId,
      'playerId': playerId,
    };
  }
}
