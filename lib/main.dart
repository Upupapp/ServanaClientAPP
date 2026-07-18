import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/config/app_config.dart';
import 'package:client/common/config/app_theme.dart';
import 'package:client/modules/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:client/modules/job_order/presentation/blocs/job_order_bloc.dart';
import 'package:client/modules/registration/presentation/bloc/registration_bloc.dart';
import 'package:client/modules/store_items/presentation/bloc/store_items_bloc.dart';
import 'package:client/modules/store_items/presentation/bloc/store_options_bloc.dart';
import 'package:client/modules/store_items/presentation/bloc/store_options_events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:client/common/domain/helpers/hive_repo.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/routes/main_router.dart';
import 'package:toastification/toastification.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Hive.initFlutter();
  HiveHelper.registerAdapters();

  final config = AppConfig.fromEnv();
  ColorPalette.applyBrand(config.brand);
  initInjector(config);

  // FreeRasp.initThreatDetection();

  runApp(MyApp(config: config));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.config});

  final AppConfig config;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _router = MainRouter.router();

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
        child: MaterialApp.router(
          title: widget.config.brand.appName,
          theme: buildAppTheme(widget.config.brand),
          routeInformationParser: _router.routeInformationParser,
          routeInformationProvider: _router.routeInformationProvider,
          routerDelegate: _router.routerDelegate,
        ),
      ),
    );
  }
}
