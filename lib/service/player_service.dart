import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/player_model.dart';

class PlayerService {
  // المرجع على مجموعة اللاعبين في فايرستور
  final CollectionReference<Map<String, dynamic>> _playersRef =
      FirebaseFirestore.instance.collection('players');

  /// إضافة لاعب جديد (يستخدمها المدرب)
  Future<void> addPlayer(PlayerModel player) async {
    await _playersRef.add(player.toMap());
  }

  /// إرجاع اللاعبين حسب الفريق (لصفحة المدرب)
  Stream<List<PlayerModel>> getPlayersByTeam(String teamId) {
    return _playersRef
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => PlayerModel.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  /// جلب لاعب واحد حسب الـ id (لصفحة تفاصيل اللاعب)
  Stream<PlayerModel> getPlayerById(String playerId) {
    return _playersRef.doc(playerId).snapshots().where((doc) => doc.exists).map(
          (doc) => PlayerModel.fromMap(
            doc.id,
            doc.data()!,
          ),
        );
  }
}
