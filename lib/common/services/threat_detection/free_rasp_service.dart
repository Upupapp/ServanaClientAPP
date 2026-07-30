import 'package:flutter/foundation.dart';
import 'package:freerasp/freerasp.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/services/threat_detection/provider/threat_detection_provider.dart';

class FreeRasp {
  static Future<void> initThreatDetection() async {
    var trigger = dpLocator<ThreatDetectionProvider>();
    // Signing hash of your app

    final config = TalsecConfig(
      /// For Android
      androidConfig: AndroidConfig(
        packageName: 'com.servana.serviceclient',
        supportedStores: ['com.android.vending'],
        signingCertHashes: [
          "ssaQxyc3v5MGw1TAFt/hRaX72HO0/7kHNDRiEKMPiTc=",
          "Jvoir3o8k9PewO8IzTOaFfM0rEtY1OuvxRbl5TtKs6M=",
        ],
      ),

      /// For iOS
      // iosConfig: IOSConfig(
      //   bundleIds: ['YOUR_APP_BUNDLE_ID'],
      //   teamId: 'M8AK35...',
      // ),
      watcherMail: 'hcalmerin+freerasp@gmail.com',
      isProd: !kDebugMode,
    );

    final callback = ThreatCallback(
      onAppIntegrity: () => trigger.protect(),
      onObfuscationIssues: () => trigger.protect(),
      onDebug: () {
        if (!kDebugMode) {
          trigger.protect();
        }
      },
      onDeviceBinding: () => trigger.protect(),
      onHooks: () => trigger.protect(),
      onPrivilegedAccess: () => trigger.protect(),
      onSecureHardwareNotAvailable: () => trigger.protect(),
      onSimulator: () {
        if (!kDebugMode) {
          trigger.protect();
        }
      },
      onUnofficialStore: () {
        if (!kDebugMode) {
          trigger.protect();
        }
      },
    );
    Talsec.instance.attachListener(callback);
    await Talsec.instance.start(config);
  }
}
