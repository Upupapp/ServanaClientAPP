import 'package:client/common/services/app_haptics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => AppHaptics.setEnabled(true));

  group('AppHaptics', () {
    test('isEnabled is true by default', () {
      AppHaptics.setEnabled(true);
      expect(AppHaptics.isEnabled, isTrue);
    });

    test('setEnabled(false) disables haptics', () {
      AppHaptics.setEnabled(false);
      expect(AppHaptics.isEnabled, isFalse);
    });

    test('setEnabled(true) re-enables haptics after disable', () {
      AppHaptics.setEnabled(false);
      AppHaptics.setEnabled(true);
      expect(AppHaptics.isEnabled, isTrue);
    });
  });
}
