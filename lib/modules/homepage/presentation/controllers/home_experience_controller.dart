import 'package:flutter/widgets.dart';
import '../../domain/home_promotion.dart';

class HomeExperienceController extends ChangeNotifier {
  HomeEntryContext _entryContext = HomeEntryContext.returningLaunch;
  HomeVisualQuality _visualQuality = HomeVisualQuality.full;
  bool _hasCompletedFirstEntrance = false;

  HomeEntryContext get entryContext => _entryContext;
  HomeVisualQuality get visualQuality => _visualQuality;
  bool get isFirstArrival =>
      _entryContext == HomeEntryContext.firstAfterOnboarding &&
      !_hasCompletedFirstEntrance;
  bool get shouldAnimateEntrance =>
      isFirstArrival ||
      (_entryContext == HomeEntryContext.returningLaunch &&
          !_hasCompletedFirstEntrance);

  void resolveEntryContext(HomeEntryContext context) {
    _entryContext = context;
    notifyListeners();
  }

  void resolveVisualQuality(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _visualQuality = HomeVisualQuality.staticQuality;
    } else {
      _visualQuality = HomeVisualQuality.full;
    }
    notifyListeners();
  }

  void markEntranceComplete() {
    _hasCompletedFirstEntrance = true;
    notifyListeners();
  }

  void resetForLogout() {
    _hasCompletedFirstEntrance = false;
    _entryContext = HomeEntryContext.returningLaunch;
    notifyListeners();
  }
}
