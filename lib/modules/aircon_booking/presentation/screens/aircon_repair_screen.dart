import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/widgets/service_category_list_screen.dart';
import 'package:client/modules/aircon_booking/data/aircon_booking_store.dart';
import 'package:client/modules/aircon_booking/presentation/screens/aircon_options_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

class AirconRepairScreen extends StatefulWidget {
  static const String routeName = 'AirconRepair';
  static const String route = 'AirconRepair';

  const AirconRepairScreen({super.key});

  @override
  State<AirconRepairScreen> createState() => _AirconRepairScreenState();
}

class _AirconRepairScreenState extends State<AirconRepairScreen> {
  final store = dpLocator<AirconBookingStore>();

  @override
  void initState() {
    super.initState();
    store.reset();
    store.loadOptionsWithAddons(serviceId: 1);
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (context) {
      final items = store.bookableOptions
          .map((o) => ServiceCardModel(
                raw: o,
                name: (o['level_3'] ?? o['name'] ?? o['optionName'] ?? 'Aircon Service')
                    .toString(),
                categoryKey: (o['level_2'] ?? '').toString(),
                price: ServiceCardModel.extractPrice(o),
              ))
          .toList();

      return ServiceCategoryListScreen(
        title: 'Aircon Repair',
        filterChips: const ['All', 'Cleaning', 'Installation', 'Repair'],
        items: items,
        isLoading: store.isLoading,
        errorMessage: store.errorMessage,
        onRetry: () => store.loadOptionsWithAddons(serviceId: 1),
        onCardTap: (ctx, model) {
          store.selectOption(model.raw as Map<String, dynamic>);
          ctx.pushNamed(AirconOptionsScreen.routeName);
        },
      );
    });
  }
}
