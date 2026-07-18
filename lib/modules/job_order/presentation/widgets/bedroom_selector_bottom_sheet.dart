import 'package:flutter/material.dart';
import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/data/models/merchant_service.dart';

/// Result returned when the user confirms service quantity selection.
class BedroomSelectionResult {
  /// For backward compatibility, this represents quantity (sessions, hours, etc.)
  final int bedroomCount;

  /// Duration in hours (for hourly services) or same as quantity for per-session services
  final int durationHours;

  const BedroomSelectionResult({
    required this.bedroomCount,
    required this.durationHours,
  });
}

/// Determines the type of quantity selector to show based on service
enum ServiceQuantityType {
  perSession,
  perHour,
  perUnit,
}

/// A bottom sheet that asks the user to select service quantity
/// (sessions, hours, etc.) based on the service type.
class BedroomSelectorBottomSheet extends StatefulWidget {
  final MerchantServiceModel service;

  const BedroomSelectorBottomSheet({
    super.key,
    required this.service,
  });

  /// Shows the service quantity selector bottom sheet and returns the selection result.
  /// Returns null if the user dismisses without selecting.
  static Future<BedroomSelectionResult?> show(
    BuildContext context, {
    required MerchantServiceModel service,
  }) {
    return showModalBottomSheet<BedroomSelectionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BedroomSelectorBottomSheet(service: service),
    );
  }

  @override
  State<BedroomSelectorBottomSheet> createState() =>
      _BedroomSelectorBottomSheetState();
}

class _BedroomSelectorBottomSheetState
    extends State<BedroomSelectorBottomSheet> {
  int _quantity = 1;

  /// Determines the quantity type based on service recommendation
  ServiceQuantityType get _quantityType {
    final recommendation = widget.service.recommendation.toLowerCase();
    if (recommendation.contains('hour')) {
      return ServiceQuantityType.perHour;
    }
    if (recommendation.contains('unit')) {
      return ServiceQuantityType.perUnit;
    }
    return ServiceQuantityType.perSession;
  }

  /// Get the subcategory name for display
  String get _subcategoryName {
    return widget.service.merchantSubcategoryName ??
        widget.service.merchantCategoryName ??
        'Service';
  }

  /// Get the question text based on service type
  String get _questionText {
    switch (_quantityType) {
      case ServiceQuantityType.perHour:
        return 'How many hours do you need?';
      case ServiceQuantityType.perSession:
        return 'How many sessions do you want?';
      case ServiceQuantityType.perUnit:
        return 'How many units do you have?';
    }
  }

  /// Get the unit label based on service type
  String get _unitLabel {
    switch (_quantityType) {
      case ServiceQuantityType.perHour:
        return _quantity == 1 ? 'hour' : 'hours';
      case ServiceQuantityType.perSession:
        return _quantity == 1 ? 'session' : 'sessions';
      case ServiceQuantityType.perUnit:
        return _quantity == 1 ? 'unit' : 'units';
    }
  }

  /// Get the info label based on service type
  String get _infoLabel {
    switch (_quantityType) {
      case ServiceQuantityType.perHour:
        return 'Duration';
      case ServiceQuantityType.perSession:
        return 'Sessions';
      case ServiceQuantityType.perUnit:
        return 'Units';
    }
  }

  /// Get the info value based on service type
  String get _infoValue {
    return '$_quantity $_unitLabel';
  }

  /// Calculate total price
  int get _totalPrice {
    return widget.service.amount * _quantity;
  }

  /// Get max quantity based on service type
  int get _maxQuantity {
    switch (_quantityType) {
      case ServiceQuantityType.perHour:
        return 8; // Max 8 hours
      case ServiceQuantityType.perSession:
        return 5; // Max 5 sessions
      case ServiceQuantityType.perUnit:
        return 10; // Max 10 units
    }
  }

  void _increment() {
    if (_quantity < _maxQuantity) {
      setState(() => _quantity++);
    }
  }

  void _decrement() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  void _onContinue() {
    Navigator.of(context).pop(
      BedroomSelectionResult(
        bedroomCount: _quantity,
        durationHours: _quantityType == ServiceQuantityType.perHour
            ? _quantity
            : _quantity, // For sessions, duration equals quantity
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorPalette.secondaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ColorPalette.secondaryBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Service name
              Text(
                widget.service.merchantServiceName,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ColorPalette.primaryColorDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              // Subcategory badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: ColorPalette.primaryColorLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _subcategoryName,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: ColorPalette.primaryColorDark,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Question
              Text(
                _questionText,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: ColorPalette.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Counter
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CounterButton(
                    icon: Icons.remove,
                    onPressed: _quantity > 1 ? _decrement : null,
                  ),
                  Container(
                    width: 80,
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Text(
                          '$_quantity',
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: ColorPalette.secondaryText,
                          ),
                        ),
                        Text(
                          _unitLabel,
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontSize: 12,
                            color: ColorPalette.accentText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _CounterButton(
                    icon: Icons.add,
                    onPressed: _quantity < _maxQuantity ? _increment : null,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorPalette.primaryColorLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _quantityType == ServiceQuantityType.perHour
                                  ? Icons.schedule
                                  : _quantityType == ServiceQuantityType.perUnit
                                      ? Icons.ac_unit_rounded
                                      : Icons.confirmation_number_outlined,
                              size: 20,
                              color: ColorPalette.primaryColorDark,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$_infoLabel:',
                              style: TextStyle(
                                fontFamily: FontPalette.primaryFontFamily,
                                fontSize: 14,
                                color: ColorPalette.accentText,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _infoValue,
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: ColorPalette.secondaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.payments_outlined,
                              size: 20,
                              color: ColorPalette.primaryColorDark,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Total:',
                              style: TextStyle(
                                fontFamily: FontPalette.primaryFontFamily,
                                fontSize: 14,
                                color: ColorPalette.accentText,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '₱$_totalPrice',
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: ColorPalette.primaryColorDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.primaryColorDark,
                    foregroundColor: ColorPalette.primaryButtonTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _CounterButton({
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(
              color: isEnabled
                  ? ColorPalette.primaryColorDark
                  : ColorPalette.secondaryBorder,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isEnabled
                ? ColorPalette.primaryColorDark
                : ColorPalette.secondaryBorder,
            size: 24,
          ),
        ),
      ),
    );
  }
}
