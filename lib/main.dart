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
import 'package:client/modules/notifications/presentation/foreground_notification_banner.dart';
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
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    }
  }

  final config = AppConfig.fromEnv();
  ColorPalette.applyBrand(config.brand);
  initInjector(config);

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
  }

  @override
  void dispose() {
    _screenObserver.detach();
    _lifecycleCoord.detach();
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
            darkTheme: buildDarkAppTheme(widget.config.brand),
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
