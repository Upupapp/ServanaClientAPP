import 'package:client/common/constants/color_palette.dart';
import 'package:client/modules/categories/data/category_addon_filter.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/widgets/service_category_list_screen.dart';
import 'package:client/modules/aircon_booking/data/aircon_booking_store.dart';
import 'package:client/modules/aircon_booking/presentation/screens/aircon_checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

/// Step 1: User picks an aircon service option, HP, height, distance, add-ons
/// and receives a live price quote from the Servana API.
class AirconOptionsScreen extends StatefulWidget {
  static const String routeName = 'AirconOptions';
  static const String route = 'AirconOptions';

  const AirconOptionsScreen({super.key});

  @override
  State<AirconOptionsScreen> createState() => _AirconOptionsScreenState();
}

class _AirconOptionsScreenState extends State<AirconOptionsScreen> {
  final store = dpLocator<AirconBookingStore>();

  static const _hpKeys = ['1hp', '1.5hp', '2hp', '2.5hp', '3hp'];
  static const _heightKeys = [
    'ground_floor',
    '2nd_floor',
    '3rd_floor',
    '4th_floor',
  ];
  static const _distanceKeys = [
    '0-5km',
    '5-10km',
    '10-20km',
    '20-30km',
  ];

  @override
  void initState() {
    super.initState();
    // Callers (AirconRepairScreen, search, home recommended) pre-select an
    // option before pushing this screen. Preserve it across the reset so the
    // user doesn't have to pick the same service twice.
    final preSelected = store.selectedOption;
    store.reset();
    if (preSelected != null) {
      store.selectOption(preSelected);
    }
    store.loadOptionsWithAddons(serviceId: 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Aircon Service',
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
          return const Center(child: CircularProgressIndicator());
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
                    onPressed: () => store.loadOptionsWithAddons(serviceId: 1),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final options = store.optionsWithAddons;

        // MAIN options live at the top level; ADD_ONs are nested under each
        // main option's `addons[]` array (see /api/{serviceId}/options-with-addons).
        final displayOptions =
            options.where(CategoryAddonFilter.isNotAddon).toList();

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
              const _SectionTitle('Select Service'),
              const SizedBox(height: 8),
              ...displayOptions.map((opt) {
                final id = opt['id'] ?? opt['optionId'];
                final name = opt['level_3'] ??
                    opt['name'] ??
                    opt['optionName'] ??
                    'Option $id';
                final price = ServiceCardModel.extractPrice(opt);
                final selectedId = store.selectedOption?['id'] ??
                    store.selectedOption?['optionId'];
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

              const SizedBox(height: 20),
              const _SectionTitle('Horsepower'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _hpKeys.map((k) {
                  final selected = store.selectedHpKey == k;
                  return ChoiceChip(
                    label: Text(k),
                    selected: selected,
                    selectedColor: ColorPalette.primaryColorDark,
                    labelStyle: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      color: selected
                          ? ColorPalette.primaryText
                          : ColorPalette.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => store.setHpKey(k),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              const _SectionTitle('Floor / Height'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _heightKeys.map((k) {
                  final selected = store.selectedHeightKey == k;
                  return ChoiceChip(
                    label: Text(_labelify(k)),
                    selected: selected,
                    selectedColor: ColorPalette.primaryColorDark,
                    labelStyle: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      color: selected
                          ? ColorPalette.primaryText
                          : ColorPalette.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => store.setHeightKey(k),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              const _SectionTitle('Distance'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _distanceKeys.map((k) {
                  final selected = store.selectedDistanceKey == k;
                  return ChoiceChip(
                    label: Text(k),
                    selected: selected,
                    selectedColor: ColorPalette.primaryColorDark,
                    labelStyle: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      color: selected
                          ? ColorPalette.primaryText
                          : ColorPalette.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => store.setDistanceKey(k),
                  );
                }).toList(),
              ),

              if (displayAddons.isNotEmpty) ...[
                const SizedBox(height: 20),
                const _SectionTitle('Add-ons'),
                const SizedBox(height: 8),
                ...displayAddons.map((addon) {
                  final id = addon['id'] ?? addon['optionId'] ?? 0;
                  final intId =
                      id is int ? id : int.tryParse(id.toString()) ?? 0;
                  final name = addon['level_3'] ??
                      addon['name'] ??
                      addon['optionName'] ??
                      'Add-on $id';
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

              // Quote section
              if (store.quoteResult != null) ...[
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
                        '₱${store.quotedTotal.toStringAsFixed(2)}',
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
              ],

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
                  onPressed: store.isLoading ? null : _onGetQuote,
                  child: store.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          store.quoteResult == null
                              ? 'Get Quote'
                              : 'Proceed to Checkout',
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

  Future<void> _onGetQuote() async {
    final errors = <String>[];
    if (store.selectedOption == null) errors.add('Select a service option.');
    if (store.selectedHpKey == null) errors.add('Select horsepower.');
    if (store.selectedHeightKey == null) errors.add('Select floor / height.');
    if (store.selectedDistanceKey == null) errors.add('Select distance.');

    if (errors.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errors.join('\n'))),
      );
      return;
    }

    if (store.quoteResult == null) {
      await store.getQuote();
    } else {
      if (!mounted) return;
      context.pushNamed(AirconCheckoutScreen.routeName);
    }
  }

  String _labelify(String key) => key
      .replaceAll('_', ' ')
      .replaceFirstMapped(RegExp(r'^.'), (m) => m.group(0)!.toUpperCase());
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
                  Icons.ac_unit_rounded,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
