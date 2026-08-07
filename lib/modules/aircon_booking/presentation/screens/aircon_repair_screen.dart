import 'package:client/common/domain/services/service_category_config.dart';
import 'package:client/common/domain/services/service_option_display.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/category_delight/category_reveal_overlay.dart';
import 'package:client/common/presentation/widgets/service_category_list_screen.dart';
import 'package:client/common/services/category_experience_history.dart';
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
  static const _categoryId = ServiceCategoryId.aircon;
  static const _config = CategoryRegistry.aircon;

  final store = dpLocator<AirconBookingStore>();
  late bool _isFirstView;
  bool _showReveal = true;

  @override
  void initState() {
    super.initState();
    _isFirstView = !CategoryExperienceHistory.hasSeenFirstView(_categoryId);
    CategoryExperienceHistory.markFirstViewSeen(_categoryId);
    store.clearSelectionOnly();
    store.ensureOptionsLoaded(serviceId: 1);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Observer(builder: (context) {
          final items = store.bookableOptions
              .map((o) => ServiceCardModel(
                    raw: o,
                    name: ServiceOptionDisplay.name(
                      o,
                      fallback: 'Aircon Service',
                    ),
                    categoryKey: ServiceOptionDisplay.categoryFor(o, const {
                      'Cleaning': ['clean'],
                      'Installation': ['install'],
                      'Repair': ['repair', 'checkup', 'diagnostic'],
                    }),
                    price: ServiceCardModel.extractPrice(o),
                  ))
              .toList();

          return ServiceCategoryListScreen(
            title: 'Aircon Services',
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
        }),
        if (_showReveal)
          Positioned.fill(
            child: CategoryRevealOverlay(
              config: _config,
              isFirstView: _isFirstView,
              onDismiss: () => setState(() => _showReveal = false),
            ),
          ),
      ],
    );
  }
}
