import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/widgets/service_category_list_screen.dart';
import 'package:client/modules/bw_booking/data/bw_booking_store.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_addons_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

class HairNailsScreen extends StatefulWidget {
  static const String routeName = 'HairNails';
  static const String route = 'HairNails';

  const HairNailsScreen({super.key});

  @override
  State<HairNailsScreen> createState() => _HairNailsScreenState();
}

class _HairNailsScreenState extends State<HairNailsScreen> {
  final store = dpLocator<BwBookingStore>();
  static final _matcher = RegExp(r'hair|nail|manicure|pedicure', caseSensitive: false);

  @override
  void initState() {
    super.initState();
    store.reset();
    store.loadOptionsWithAddons(serviceId: 2);
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (context) {
      final items = store.bookableOptions
          .where((o) => _matcher.hasMatch((o['level_2'] ?? '').toString()))
          .map((o) => ServiceCardModel(
                raw: o,
                name: (o['level_3'] ?? o['name'] ?? o['optionName'] ?? 'Service')
                    .toString(),
                categoryKey: (o['level_2'] ?? '').toString(),
                price: ServiceCardModel.extractPrice(o),
              ))
          .toList();

      return ServiceCategoryListScreen(
        title: 'Hair & Nails',
        filterChips: const ['All', 'Hair', 'Nails'],
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
