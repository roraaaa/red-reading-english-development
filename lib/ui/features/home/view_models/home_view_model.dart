import 'package:flutter/foundation.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/progress_repository.dart';
import '../../../../domain/models/attempt.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required AuthRepository auth, required ProgressRepository progress})
    : _auth = auth,
      _progress = progress {
    _auth.addListener(notifyListeners);
    _progress.addListener(notifyListeners);
  }

  final AuthRepository _auth;
  final ProgressRepository _progress;

  String get firstName => _auth.currentUser?.firstName ?? 'Reader';
  String get initial => firstName.isEmpty ? 'R' : firstName[0].toUpperCase();
  int get totalStars => _progress.totalMaterialStars;
  int get storiesRead => _progress.storiesCompleted;
  int get assessmentsTaken => _progress.assessments.length;

  Attempt? get lastAssessment {
    final list = _progress.assessments;
    return list.isEmpty ? null : list.first;
  }

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> signOut() => _auth.signOut();

  @override
  void dispose() {
    _auth.removeListener(notifyListeners);
    _progress.removeListener(notifyListeners);
    super.dispose();
  }
}
