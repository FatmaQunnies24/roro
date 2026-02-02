import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/assessment_model.dart';

class AssessmentService {
  final CollectionReference<Map<String, dynamic>> _assessmentsRef =
      FirebaseFirestore.instance.collection('assessments');

  /// إضافة تقييم جديد
  Future<String> addAssessment(AssessmentModel assessment) async {
    final docRef = await _assessmentsRef.add(assessment.toMap());
    return docRef.id;
  }

  /// ترتيب التقييمات من الأحدث للأقدم (بدون فهرس مركب في Firestore)
  static List<AssessmentModel> _sortByTimestampDesc(List<AssessmentModel> list) {
    final copy = List<AssessmentModel>.from(list);
    copy.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return copy;
  }

  /// جلب جميع تقييمات مستخدم معين (Stream — بدون orderBy لتفادي طلب فهرس مركب)
  Stream<List<AssessmentModel>> getUserAssessments(String userId) {
    return _assessmentsRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = <AssessmentModel>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (data.isEmpty) continue;
          list.add(AssessmentModel.fromMap(doc.id, data));
        } catch (_) {
          continue;
        }
      }
      return _sortByTimestampDesc(list);
    });
  }

  /// جلب تقييمات المستخدم مرة واحدة (Future) — بدون orderBy لتفادي خطأ الفهرس
  Future<List<AssessmentModel>> getUserAssessmentsOnce(String userId) async {
    if (userId.isEmpty) return [];
    final snapshot = await _assessmentsRef
        .where('userId', isEqualTo: userId)
        .get();
    final list = <AssessmentModel>[];
    for (final doc in snapshot.docs) {
      try {
        final data = doc.data();
        if (data.isEmpty) continue;
        list.add(AssessmentModel.fromMap(doc.id, data));
      } catch (_) {
        continue;
      }
    }
    return _sortByTimestampDesc(list);
  }

  /// جلب تقييم معين
  Future<AssessmentModel?> getAssessmentById(String assessmentId) async {
    try {
      final doc = await _assessmentsRef.doc(assessmentId).get();
      if (doc.exists && doc.data() != null) {
        return AssessmentModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// حذف تقييم
  Future<void> deleteAssessment(String assessmentId) async {
    await _assessmentsRef.doc(assessmentId).delete();
  }
}

