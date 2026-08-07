import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/widgets/booking_ux_components.dart';
import 'package:client/common/presentation/widgets/service_category_list_screen.dart';
import 'package:client/modules/bw_booking/data/bw_booking_store.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_branch_slot_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

/// Pre-picked-option add-ons step. Reached from search and the home
/// recommended carousel after the user taps a specific B&W service
/// (e.g. Gluta Drip). The catalog flow doesn't pass through here —
/// it uses [BwOptionsScreen] to pick a main option first.
///
/// If the selected option has no add-ons (most B&W services), this
/// screen still renders a summary + Continue so the user gets a
/// confirmation beat before scheduling.
class BwAddOnsScreen extends StatefulWidget {
  static const String routeName = 'BwAddOns';
  static const String route = 'BwAddOns';

  const BwAddOnsScreen({super.key});

  @override
  State<BwAddOnsScreen> createState() => _BwAddOnsScreenState();
}

class _BwAddOnsScreenState extends State<BwAddOnsScreen> {
  final store = dpLocator<BwBookingStore>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Add-ons',
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
        final selected = store.selectedOption;
        if (selected == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No service selected. Please go back and pick a service.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  color: ColorPalette.secondaryText,
                ),
              ),
            ),
          );
        }

        final addons = <Map<String, dynamic>>[];
        final nested = selected['addons'];
        if (nested is List) {
          addons.addAll(nested.cast<Map<String, dynamic>>());
        }

        final name = (selected['level_3'] ??
                selected['name'] ??
                selected['optionName'] ??
                'Service')
            .toString();
        final category = (selected['level_2'] ?? '').toString();
        final basePrice = ServiceCardModel.extractPrice(selected);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BookingStageHeader(
                current: 2,
                total: 5,
                label: 'Optional add-ons',
              ),
              // Service summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorPalette.primaryColorLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (category.isNotEmpty)
                      Text(
                        category,
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          color: ColorPalette.accentText,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: ColorPalette.primaryColorDark,
                      ),
                    ),
                    if (basePrice != 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '₱${ServiceCardModel.formatPrice(basePrice)}',
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          fontWeight: FontWeight.w700,
                          color: ColorPalette.primaryColorDark,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (addons.isNotEmpty) ...[
                const _SectionTitle('Add to your service'),
                const SizedBox(height: 4),
                Text(
                  'Optional — tap to include in this booking.',
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    color: ColorPalette.accentText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                ...addons.map((addon) {
                  final id = addon['id'] ?? 0;
                  final intId =
                      id is int ? id : int.tryParse(id.toString()) ?? 0;
                  final addonName =
                      addon['level_3'] ?? addon['name'] ?? 'Add-on $id';
                  final price = ServiceCardModel.extractPrice(addon);
                  final isSelected = store.selectedAddonIds.contains(intId);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (_) => store.toggleAddon(intId),
                    title: Text(
                      addonName.toString(),
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: price != 0
                        ? Text(
                            '₱${ServiceCardModel.formatPrice(price)}',
                            style: TextStyle(
                              color: ColorPalette.primaryColorDark,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                    activeColor: ColorPalette.primaryColorDark,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  );
                }),
                const SizedBox(height: 16),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No add-ons available for this service.',
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      color: ColorPalette.accentText,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Estimated total
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorPalette.secondaryBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ColorPalette.border(.55)),
                ),
                child: Row(
                  children: [
                    Text(
                      'Estimated Total',
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w600,
                        color: ColorPalette.secondaryText,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '₱${store.estimatedTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: ColorPalette.primaryColorDark,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

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
                  onPressed: () =>
                      context.pushNamed(BwBranchSlotScreen.routeName),
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
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: FontPalette.primaryFontFamily,
        fontWeight: FontWeight.w700,
        fontSize: 16,
        color: ColorPalette.secondaryText,
      ),
    );
  }
}
