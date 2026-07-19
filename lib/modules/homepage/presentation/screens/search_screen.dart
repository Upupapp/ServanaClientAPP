import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/widgets/service_category_list_screen.dart';
import 'package:client/modules/aircon_booking/data/aircon_booking_store.dart';
import 'package:client/modules/aircon_booking/presentation/screens/aircon_options_screen.dart';
import 'package:client/modules/bw_booking/data/bw_booking_store.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_addons_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

class SearchScreen extends StatefulWidget {
  static String routeName = "SearchScreen";
  static String route = "SearchScreen";
  const SearchScreen({super.key});

  @override
  SearchScreenState createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  final bwStore = dpLocator<BwBookingStore>();
  final airconStore = dpLocator<AirconBookingStore>();

  @override
  void initState() {
    super.initState();
    bwStore.ensureOptionsLoaded(serviceId: 2);
    airconStore.ensureOptionsLoaded(serviceId: 1);
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (context) {
      final bwItems = bwStore.bookableOptions
          .map((o) => _Tagged(raw: o, source: _Source.bw));
      final airconItems = airconStore.bookableOptions
          .map((o) => _Tagged(raw: o, source: _Source.aircon));

      final items = [...bwItems, ...airconItems]
          .map((t) => ServiceCardModel(
                raw: t,
                name: (t.raw['level_3'] ??
                        t.raw['name'] ??
                        t.raw['optionName'] ??
                        'Service')
                    .toString(),
                categoryKey: t.source == _Source.bw ? 'beauty' : 'aircon',
                price: ServiceCardModel.extractPrice(t.raw),
              ))
          .toList();

      final isLoading = bwStore.isLoading || airconStore.isLoading;
      final errorMessage = bwStore.errorMessage ?? airconStore.errorMessage;

      return ServiceCategoryListScreen(
        title: 'Search',
        filterChips: const ['All', 'Aircon', 'Beauty'],
        items: items,
        isLoading: isLoading,
        errorMessage: errorMessage,
        onRetry: () {
          bwStore.loadOptionsWithAddons(serviceId: 2);
          airconStore.loadOptionsWithAddons(serviceId: 1);
        },
        onCardTap: (ctx, model) {
          final tagged = model.raw as _Tagged;
          if (tagged.source == _Source.bw) {
            bwStore.selectOption(tagged.raw);
            ctx.pushNamed(BwAddOnsScreen.routeName);
          } else {
            airconStore.selectOption(tagged.raw);
            ctx.pushNamed(AirconOptionsScreen.routeName);
          }
        },
      );
    });
  }
}

enum _Source { bw, aircon }

class _Tagged {
  _Tagged({required this.raw, required this.source});
  final Map<String, dynamic> raw;
  final _Source source;
}
