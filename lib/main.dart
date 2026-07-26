import 'dart:async';

import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/config/app_config.dart';
import 'package:client/common/config/app_theme.dart';
import 'package:client/firebase_options.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_bloc.dart';
import 'package:client/modules/registration/presentation/bloc/registration_bloc.dart';
import 'package:client/modules/store_items/presentation/bloc/store_items_bloc.dart';
import 'package:client/modules/store_items/presentation/bloc/store_options_bloc.dart';
import 'package:client/modules/store_items/presentation/bloc/store_options_events.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:client/common/domain/helpers/hive_repo.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/routes/main_router.dart';
import 'package:client/modules/settings/application/settings_controller.dart';
import 'package:toastification/toastification.dart';

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
    if (!kDebugMode) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    }
  }

  final config = AppConfig.fromEnv();
  ColorPalette.applyBrand(config.brand);
  initInjector(config);

  runApp(MyApp(config: config));
}

void _onZoneError(Object error, StackTrace stack) {
  if (!kDebugMode) {
    // Guard: Crashlytics requires Firebase to be initialized. If this handler
    // fires before initializeApp() completes (e.g. Hive failure), the call
    // itself would throw FirebaseException(app-not-initialized) and create a
    // second unhandled exception — so we swallow any secondary failure here.
    try {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
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

  @override
  void initState() {
    super.initState();
    _settingsCtrl = dpLocator<SettingsController>();
    _settingsCtrl.load();
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
          ),
        ),
      ),
    );
  }
}
