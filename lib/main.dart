import 'dart:async';

import 'package:client/common/constants/color_palette.dart';

import 'package:client/common/config/app_config.dart';
import 'package:client/common/config/app_theme.dart';
import 'package:client/core/analytics/application/analytics_context_provider.dart';
import 'package:client/core/analytics/application/analytics_coordinator.dart';
import 'package:client/core/analytics/application/screen_analytics_observer.dart';
import 'package:client/core/observability/safe_diagnostics.dart';
import 'package:client/core/recovery/app_lifecycle_coordinator.dart';
import 'package:client/core/recovery/connectivity_monitor.dart';
import 'package:client/core/recovery/offline_banner.dart';
import 'package:client/firebase_options.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_bloc.dart';
import 'package:client/modules/notifications/application/fcm_coordinator.dart';
import 'package:client/modules/notifications/application/notification_navigation_coordinator.dart';
import 'package:client/modules/notifications/data/notification_mapper.dart';
import 'package:client/modules/notifications/presentation/foreground_notification_banner.dart';
import 'package:client/common/services/threat_detection/free_rasp_service.dart';
import 'package:client/modules/registration/presentation/bloc/registration_bloc.dart';
import 'package:client/modules/store_items/presentation/bloc/store_items_bloc.dart';
import 'package:client/modules/store_items/presentation/bloc/store_options_bloc.dart';
import 'package:client/modules/store_items/presentation/bloc/store_options_events.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:client/common/domain/helpers/hive_repo.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/routes/main_router.dart';
import 'package:client/modules/settings/application/settings_controller.dart';
import 'package:toastification/toastification.dart';

/// Background/terminated-state FCM handler.
/// Must be a top-level function annotated with @pragma('vm:entry-point').
/// Runs in an isolate — no BuildContext, no GetIt singletons.
/// Only safe to use: Firebase services + SharedPreferences.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase must be initialized before any Firebase call in a background isolate.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Notification display is handled by the OS (FCM data+notification payload).
  // No additional work needed here beyond ensuring Firebase is initialised.
}

void main() {
  runZonedGuarded(_bootstrap, _onZoneError);
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  HiveHelper.registerAdapters();

  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FcmCoordinator.initHandlers();
    if (!kDebugMode) {
      // C21: Only capture Flutter framework fatal errors here.
      // Zone errors are handled separately below with non-fatal classification.
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
    }
  }

  final config = AppConfig.fromEnv();
  ColorPalette.applyBrand(config.brand);
  initInjector(config);

  // C24: Start freeRASP runtime protection. Runs on Android, and on iOS once
  // the build supplies --dart-define=APPLE_TEAM_ID.
  //
  // This used `.ignore()`, which discarded every failure — including the
  // ConfigurationException freeRASP threw on every iOS launch while iosConfig
  // was absent. So the SDK never started on iOS and nothing said so.
  //
  // FreeRasp now declines to start rather than throwing when a platform has no
  // configuration, so this catch is back to covering genuine startup faults.
  // Startup still must not block on it.
  if (!kIsWeb) {
    unawaited(
      FreeRasp.initThreatDetection().catchError((Object e, StackTrace s) {
        try {
          // Non-fatal: the app is fully usable without RASP, and reporting it
          // as a crash would misstate the crash rate. It should still be
          // visible rather than discarded.
          FirebaseCrashlytics.instance.recordError(e, s, fatal: false);
        } catch (_) {}
      }),
    );
  }

  // C21: Initialize analytics context (platform, version, environment).
  await AnalyticsContextProvider.instance.init(
    environment: kDebugMode ? 'development' : 'production',
  );

  // C21: Initialize analytics coordinator (loads consent from storage).
  await dpLocator<AnalyticsCoordinator>().init();

  runApp(MyApp(config: config));
}

void _onZoneError(Object error, StackTrace stack) {
  if (!kDebugMode) {
    // C21 Fix: distinguish fatal vs. non-fatal zone errors.
    // Routine offline/network errors MUST NOT be reported as crashes —
    // doing so inflates crash rate and misleads reliability dashboards.
    final isRoutine = SafeDiagnostics.isRoutine(error);
    try {
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        // Only truly unrecoverable errors are fatal.
        // Routine errors (network, timeout, 4xx/5xx) are non-fatal.
        fatal: !isRoutine,
      );
    } catch (_) {}
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.config});

  final AppConfig config;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _router = MainRouter.router();
  late final SettingsController _settingsCtrl;
  late final FcmCoordinator _fcmCoord;
  late final NotificationNavigationCoordinator _navCoord;
  late final AppLifecycleCoordinator _lifecycleCoord;
  late final ConnectivityMonitor _connectivity;
  late final ScreenAnalyticsObserver _screenObserver;

  @override
  void initState() {
    super.initState();
    _settingsCtrl = dpLocator<SettingsController>();
    _settingsCtrl.load();
    _fcmCoord = dpLocator<FcmCoordinator>();
    _navCoord = dpLocator<NotificationNavigationCoordinator>();
    _connectivity = dpLocator<ConnectivityMonitor>();

    // C21: Attach GoRouter screen observer for centralized screen_view tracking.
    _screenObserver = ScreenAnalyticsObserver(
      router: _router,
      coordinator: dpLocator<AnalyticsCoordinator>(),
    );
    _screenObserver.attach();

    // Rebuild AppLifecycleCoordinator with the messaging store resume callback,
    // then attach it to the WidgetsBinding.
    _lifecycleCoord = dpLocator<AppLifecycleCoordinator>();
    _lifecycleCoord.attach();

    // STITCH FAIL-01: handle notification taps when app was terminated (cold start).
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final data = <String, dynamic>{
          ...message.data,
          'title': message.notification?.title ??
              message.data['title'] as String? ??
              '',
          'body': message.notification?.body ??
              message.data['body'] as String? ??
              '',
        };
        final notification = mapFcmDataToNotification(data);
        if (notification != null) _navCoord.navigateTo(context, notification);
      });
    });

    // STITCH FAIL-01: handle notification taps when app was backgrounded.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (!mounted) return;
      final data = <String, dynamic>{
        ...message.data,
        'title': message.notification?.title ??
            message.data['title'] as String? ??
            '',
        'body':
            message.notification?.body ?? message.data['body'] as String? ?? '',
      };
      final notification = mapFcmDataToNotification(data);
      if (notification != null) _navCoord.navigateTo(context, notification);
    });
  }

  @override
  void dispose() {
    _screenObserver.detach();
    _lifecycleCoord.detach();
    _connectivity.dispose(); // STITCH WARN-03
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          lazy: true,
          create: (_) => dpLocator<AuthenticationBloc>(),
        ),
        BlocProvider(
          lazy: true,
          create: (_) => dpLocator<RegistrationBloc>(),
        ),
        BlocProvider(
          lazy: true,
          create: (_) => dpLocator<JobOrderBloc>(),
        ),
        BlocProvider(
          lazy: true,
          create: (_) => dpLocator<StoreItemsBloc>(),
        ),
        BlocProvider(
          lazy: true,
          create: (_) =>
              dpLocator<StoreOptionsBloc>()..add(const LoadStoreOptionsEvent()),
        ),
      ],
      child: ToastificationWrapper(
        child: ListenableBuilder(
          listenable: _settingsCtrl,
          builder: (context, _) => MaterialApp.router(
            title: widget.config.brand.appName,
            theme: buildAppTheme(widget.config.brand),

            // Dark mode is not implemented, so a device in dark mode must still
            // get the light theme.
            //
            // `ColorPalette` is a set of mutable statics with one set of values:
            // secondaryText is #111827 (near-black) and accentText is #6B7280
            // (grey), and `applyBrand()` reassigns them to those same light
            // values at startup. Nothing anywhere sets a dark variant. Those two
            // colours are read directly in 79 files, 530 times, bypassing the
            // ThemeData entirely — so `buildDarkAppTheme` produced dark surfaces
            // underneath text that stayed near-black.
            //
            // 39 of the 59 screens hardcode a light scaffold background and were
            // unaffected, which is why this survived: the app looked fine
            // wherever someone had pinned a colour, and broke on the screens
            // that trusted the theme. Create Account declares no background at
            // all, so on a dark phone its heading, its "Already have an account?"
            // line and its terms-and-conditions text were near-black on
            // near-black — the signup screen, unreadable, in production.
            //
            // Settings → Appearance already tells the truth here: it offers only
            // System Default and Light, and shows Dark as "being added in a
            // future update". This makes the app behave the way that screen
            // already describes. Restore `buildDarkAppTheme` once the palette
            // has real dark values — the theme itself is fine, the tokens it
            // sits on are not.
            darkTheme: buildAppTheme(widget.config.brand),
            themeMode: _settingsCtrl.themeMode,
            routeInformationParser: _router.routeInformationParser,
            routeInformationProvider: _router.routeInformationProvider,
            routerDelegate: _router.routerDelegate,
            builder: (context, child) => OfflineBanner(
              monitor: _connectivity,
              child: ForegroundNotificationBanner(
                fcmCoordinator: _fcmCoord,
                navigationCoordinator: _navCoord,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
