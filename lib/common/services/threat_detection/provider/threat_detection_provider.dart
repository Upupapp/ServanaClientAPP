import 'package:flutter/widgets.dart';

class ThreatDetectionProvider extends ChangeNotifier {
  bool isUnderThreat = false;

  void protect() {
    isUnderThreat = true;
    notifyListeners();
  }

  void protectDisengage() {
    isUnderThreat = false;
    notifyListeners();
  }
}
