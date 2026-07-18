import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/widgets/service_category_list_screen.dart';
import 'package:client/modules/bw_booking/data/bw_booking_store.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_addons_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

class BeautyWellnessScreen extends StatefulWidget {
  static const String routeName = 'BeautyWellness';
  static const String route = 'BeautyWellness';

  const BeautyWellnessScreen({super.key});

  @override
  State<BeautyWellnessScreen> createState() => _BeautyWellnessScreenState();
}

class _BeautyWellnessScreenState extends State<BeautyWellnessScreen> {
  final store = dpLocator<BwBookingStore>();

  @override
  void initState() {
    super.initState();
    store.reset();
    store.loadOptionsWithAddons(serviceId: 2);
  }

  static const _allowedLevel2 = {'drip', 'facial'};

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (context) {
      final items = store.bookableOptions
          .where((o) => _allowedLevel2
              .contains((o['level_2'] ?? '').toString().toLowerCase()))
          .map((o) => ServiceCardModel(
                raw: o,
                name: (o['level_3'] ?? o['name'] ?? o['optionName'] ?? 'Service')
                    .toString(),
                categoryKey: (o['level_2'] ?? '').toString(),
                price: ServiceCardModel.extractPrice(o),
              ))
          .toList();

      return ServiceCategoryListScreen(
        title: 'Beauty',
        filterChips: const ['All', 'Drip', 'Facial'],
        items: items,
        isLoading: store.isLoading,
        errorMessage: store.errorMessage,
        onRetry: () => store.loadOptionsWithAddons(serviceId: 2),
        onCardTap: (ctx, model) {
          store.selectOption(model.raw as Map<String, dynamic>);
          ctx.pushNamed(BwAddOnsScreen.routeName);
        },
      );
    });
  }
}
