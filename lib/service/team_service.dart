import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/team_model.dart';
import '../service/user_service.dart';
import '../service/player_service.dart';

class TeamService {
  final CollectionReference<Map<String, dynamic>> _teamsRef =
      FirebaseFirestore.instance.collection('teams');

  /// إضافة فريق جديد
  Future<void> addTeam(TeamModel team) async {
    await _teamsRef.doc(team.id).set(team.toMap());
  }

  /// جلب جميع الفرق
  Stream<List<TeamModel>> getAllTeams() {
    return _teamsRef.snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => TeamModel.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  /// جلب فريق واحد حسب المعرف
  Future<TeamModel?> getTeamById(String teamId) async {
    try {
      final doc = await _teamsRef.doc(teamId).get();
      if (doc.exists && doc.data() != null) {
        return TeamModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// تحديث معلومات الفريق
  Future<void> updateTeam(TeamModel team) async {
    await _teamsRef.doc(team.id).update(team.toMap());
  }

  /// تحديث عدد اللاعبين والمدربين في الفريق
  Future<void> updateTeamCounts(String teamId) async {
    final userService = UserService();
    final playerService = PlayerService();

    // حساب عدد اللاعبين
    final players = await userService.getUsersByRole('player').first;
    final teamPlayers = players.where((p) => p.teamId == teamId).length;

    // حساب عدد المدربين
    final coaches = await userService.getUsersByRole('coach').first;
    final teamCoaches = coaches.where((c) => c.teamId == teamId).length;

    // تحديث الفريق
    await _teamsRef.doc(teamId).update({
      'playersCount': teamPlayers,
      'coachesCount': teamCoaches,
    });
  }

  /// حذف فريق
  Future<void> deleteTeam(String teamId) async {
    await _teamsRef.doc(teamId).delete();
  }
}


