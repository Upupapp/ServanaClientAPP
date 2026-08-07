import 'package:client/common/constants/color_palette.dart';
import 'package:client/modules/categories/data/category_addon_filter.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/widgets/service_category_list_screen.dart';
import 'package:client/common/presentation/widgets/booking_ux_components.dart';
import 'package:client/modules/bw_booking/data/bw_booking_store.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_branch_slot_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

/// Step 1: User picks a B&W service option and optional add-ons.
class BwOptionsScreen extends StatefulWidget {
  static const String routeName = 'BwOptions';
  static const String route = 'BwOptions';

  final int serviceId;

  const BwOptionsScreen({super.key, required this.serviceId});

  @override
  State<BwOptionsScreen> createState() => _BwOptionsScreenState();
}

class _BwOptionsScreenState extends State<BwOptionsScreen> {
  final store = dpLocator<BwBookingStore>();

  @override
  void initState() {
    super.initState();
    store.reset();
    store.loadOptionsWithAddons(serviceId: widget.serviceId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Beauty & Wellness',
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: ColorPalette.primaryColorDark,
        foregroundColor: ColorPalette.primaryText,
        elevation: 0,
      ),
      body: Observer(builder: (context) {
        if (store.isLoading && store.optionsWithAddons.isEmpty) {
          return const Center(
            child: BookingLoadingState('Loading beauty and wellness services'),
          );
        }

        if (store.errorMessage != null && store.optionsWithAddons.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: ColorPalette.danger),
                  const SizedBox(height: 12),
                  Text(
                    store.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      color: ColorPalette.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => store.loadOptionsWithAddons(
                        serviceId: widget.serviceId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final options = store.optionsWithAddons;

        final mainOptions =
            options.where(CategoryAddonFilter.isNotAddon).toList();

        // options-with-addons
        final grouped = <String, List<Map<String, dynamic>>>{};
        for (final opt in mainOptions) {
          final group = (opt['level_2'] ?? 'Other').toString();
          grouped.putIfAbsent(group, () => []).add(opt);
        }

        // Extract nested addons from the currently selected option.
        final displayAddons = <Map<String, dynamic>>[];
        if (store.selectedOption != null) {
          final nested = store.selectedOption!['addons'];
          if (nested is List) {
            displayAddons.addAll(nested.cast<Map<String, dynamic>>());
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BookingStageHeader(
                current: 1,
                total: 5,
                label: 'Choose service',
              ),
              // Render grouped services with section headers
              for (final entry in grouped.entries) ...[
                _SectionTitle(entry.key),
                const SizedBox(height: 8),
                ...entry.value.map((opt) {
                  final id = opt['id'];
                  final name = opt['level_3'] ??
                      opt['name'] ??
                      opt['optionName'] ??
                      'Option $id';
                  final price = ServiceCardModel.extractPrice(opt);
                  final selectedId = store.selectedOption?['id'];
                  final isSelected = id == selectedId;
                  return _OptionTile(
                    title: name.toString(),
                    subtitle: price != 0
                        ? '₱${ServiceCardModel.formatPrice(price)}'
                        : '',
                    selected: isSelected,
                    onTap: () => store.selectOption(opt),
                  );
                }),
                const SizedBox(height: 16),
              ],

              if (displayAddons.isNotEmpty) ...[
                const SizedBox(height: 4),
                const _SectionTitle('Add-ons'),
                const SizedBox(height: 8),
                ...displayAddons.map((addon) {
                  final id = addon['id'] ?? 0;
                  final intId =
                      id is int ? id : int.tryParse(id.toString()) ?? 0;
                  final name =
                      addon['level_3'] ?? addon['name'] ?? 'Add-on $id';
                  final price = ServiceCardModel.extractPrice(addon);
                  final isSelected = store.selectedAddonIds.contains(intId);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (_) => store.toggleAddon(intId),
                    title: Text(
                      name.toString(),
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: price != 0
                        ? Text('₱${ServiceCardModel.formatPrice(price)}',
                            style: TextStyle(
                                color: ColorPalette.primaryColorDark,
                                fontWeight: FontWeight.w700))
                        : null,
                    activeColor: ColorPalette.primaryColorDark,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  );
                }),
              ],

              const SizedBox(height: 24),

              // Estimated total
              if (store.selectedOption != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ColorPalette.primaryColorLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Estimated Total',
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          fontWeight: FontWeight.w600,
                          color: ColorPalette.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₱${store.estimatedTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          fontWeight: FontWeight.w800,
                          fontSize: 28,
                          color: ColorPalette.primaryColorDark,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Error
              if (store.errorMessage != null &&
                  store.optionsWithAddons.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    store.errorMessage!,
                    style: TextStyle(
                        color: ColorPalette.danger,
                        fontFamily: FontPalette.primaryFontFamily),
                  ),
                ),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.primaryColor,
                    foregroundColor: ColorPalette.primaryButtonTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: store.selectedOption == null ? null : _onContinue,
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  void _onContinue() {
    if (store.selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service option.')),
      );
      return;
    }
    context.pushNamed(BwBranchSlotScreen.routeName);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: FontPalette.primaryFontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: ColorPalette.secondaryText,
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        label: title,
        button: true,
        selected: selected,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: selected
                  ? ColorPalette.primaryColorDark
                  : ColorPalette.secondaryBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? ColorPalette.primaryColorDark
                    : ColorPalette.border(.55),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.spa_rounded,
                  color: selected
                      ? ColorPalette.primaryText
                      : ColorPalette.primaryColorDark,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? ColorPalette.primaryText
                          : ColorPalette.secondaryText,
                    ),
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? ColorPalette.primaryText
                          : ColorPalette.primaryColorDark,
                    ),
                  ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, size: 20, color: Colors.white),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
