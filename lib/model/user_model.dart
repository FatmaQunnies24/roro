class UserModel {
  final String id;
  final String name;
  final String role; // admin / coach / player
  final String teamId;
  final String? playerId;
  final String? email;
  final String? password; // يتم حفظه في قاعدة البيانات

  UserModel({
    required this.id,
    required this.name,
    required this.role,
    required this.teamId,
    this.playerId,
    this.email,
    this.password,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      role: data['role'] ?? '',
      teamId: data['teamId'] ?? '',
      playerId: data['playerId'],
      email: data['email'],
      password: data['password'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'teamId': teamId,
      if (playerId != null) 'playerId': playerId,
      if (email != null) 'email': email,
      if (password != null) 'password': password,
    };
  }
}
