import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/metrics_history_model.dart';

class MetricsHistoryService {
  final CollectionReference<Map<String, dynamic>> _historyRef =
      FirebaseFirestore.instance.collection('metrics_history');

  /// حفظ مواصفات جديدة في التاريخ
  Future<void> addMetricsHistory(MetricsHistoryModel history) async {
    await _historyRef.add(history.toMap());
  }

  /// جلب آخر 7 مواصفات للاعب
  Future<List<MetricsHistoryModel>> getLast7Metrics(String playerId) async {
    final snapshot = await _historyRef
        .where('playerId', isEqualTo: playerId)
        .orderBy('timestamp', descending: true)
        .limit(7)
        .get();

    return snapshot.docs
        .map((doc) => MetricsHistoryModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// جلب جميع المواصفات للاعب
  Stream<List<MetricsHistoryModel>> getAllMetrics(String playerId) {
    return _historyRef
        .where('playerId', isEqualTo: playerId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MetricsHistoryModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }
}

