import 'package:client/common/domain/services/service_category_config.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/category_delight/category_reveal_overlay.dart';
import 'package:client/common/presentation/widgets/service_category_list_screen.dart';
import 'package:client/common/services/category_experience_history.dart';
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
  static const _categoryId = ServiceCategoryId.beautyWellness;
  static const _config = CategoryRegistry.beautyWellness;
  static const _allowedLevel2 = {'drip', 'facial'};

  final store = dpLocator<BwBookingStore>();
  late bool _isFirstView;
  bool _showReveal = true;

  @override
  void initState() {
    super.initState();
    _isFirstView = !CategoryExperienceHistory.hasSeenFirstView(_categoryId);
    CategoryExperienceHistory.markFirstViewSeen(_categoryId);
    store.clearSelectionOnly();
    store.ensureOptionsLoaded(serviceId: 2);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Observer(builder: (context) {
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
