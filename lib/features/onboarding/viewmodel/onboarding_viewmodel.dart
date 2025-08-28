// 4. lib/features/onboarding/viewmodel/onboarding_viewmodel.dart
import 'package:flutter/material.dart';

class OnboardingViewModel extends ChangeNotifier {
  int currentPage = 0;

  void changePage(int index) {
    currentPage = index;
    notifyListeners();
  }
}
