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

  /// جلب جميع تقييمات مستخدم معين
  Stream<List<AssessmentModel>> getUserAssessments(String userId) {
    return _assessmentsRef
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => AssessmentModel.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
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

