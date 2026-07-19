import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/data/models/merchant_service.dart';
import 'package:client/common/domain/helpers/session_service.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/screens/address_form_screen.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart'
    show LatLong;
import 'package:client/common/presentation/widgets/app_image.dart';
import 'package:client/modules/store_items/presentation/bloc/store_items_bloc.dart';
import 'package:client/modules/store_items/presentation/bloc/store_items_events.dart';
import 'package:client/modules/store_items/presentation/bloc/store_items_states.dart';
import 'package:client/modules/store_items/presentation/screens/store_items_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class RewardsScreen extends StatefulWidget {
  static String routeName = "Rewards";
  static String route = "/Rewards";
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  int _points = 1240;
  final List<_RewardItem> _items = [
    _RewardItem(
      title: '₱100 Service Voucher',
      description: 'Valid on any service',
      cost: 500,
    ),
    _RewardItem(
      title: 'Free Transport Fee',
      description: 'Waive base transportation fee',
      cost: 750,
    ),
    _RewardItem(
      title: '₱250 Service Voucher',
      description: 'Valid on bookings above ₱1500',
      cost: 1200,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final progress = (_points / 2000).clamp(0.0, 1.0);
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: ColorPalette.secondaryText,
          ),
        ),
        title: Text(
          "Rewards",
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: ColorPalette.secondaryText,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _RewardsBalanceCard(points: _points, progress: progress),
          const SizedBox(height: 16),
          Text(
            "Redeem",
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: ColorPalette.secondaryText,
            ),
          ),
          const SizedBox(height: 10),
          ..._items.map((item) {
            final canRedeem = _points >= item.cost;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RewardItemCard(
                item: item,
                canRedeem: canRedeem,
                onRedeem: canRedeem
                    ? () {
                        setState(() {
                          _points -= item.cost;
                        });
                      }
                    : null,
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(
            "Recent activity",
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: ColorPalette.secondaryText,
            ),
          ),
          const SizedBox(height: 10),
          const _RewardHistoryTile(
            title: "Booking completed",
            subtitle: "Signature Facial • Jan 26",
            points: 120,
          ),
          const _RewardHistoryTile(
            title: "Redeemed voucher",
            subtitle: "₱100 Service Voucher • Jan 20",
            points: -500,
          ),
          const _RewardHistoryTile(
            title: "Booking completed",
            subtitle: "Body Massage • Jan 18",
            points: 90,
          ),
        ],
      ),
    );
  }
}

class FavouritesScreen extends StatefulWidget {
  static String routeName = "Favourites";
  static String route = "/Favourites";
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  static const String _merchantId = 'servana';
  static const String _merchantName = 'Servana';

  final Set<int> _favoriteIds = {};
  bool _seededFavorites = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      BlocProvider.of<StoreItemsBloc>(context)
          .add(const StoreItemLoadEvent(_merchantId));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: ColorPalette.secondaryText,
          ),
        ),
        title: Text(
          "Favourites",
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: ColorPalette.secondaryText,
          ),
        ),
      ),
      body: BlocBuilder<StoreItemsBloc, StoreItemsState>(
        builder: (context, state) {
          final bloc = BlocProvider.of<StoreItemsBloc>(context);
          final services =
              bloc.storeItemCategories.expand((c) => c.services).toList();

          if (!_seededFavorites && services.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _seededFavorites = true;
                for (final s in services.take(6)) {
                  _favoriteIds.add(s.merchantServiceID);
                }
              });
            });
          }

          final favorites = services
              .where((s) => _favoriteIds.contains(s.merchantServiceID))
              .toList();

          if (state is StoreItemLoadingState && services.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (favorites.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      color: ColorPalette.secondaryText.withOpacity(.5),
                      size: 48,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "No favourites yet",
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w700,
                        color: ColorPalette.secondaryText,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Browse services and tap the heart to save them here.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        color: ColorPalette.secondaryText.withOpacity(.7),
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.pushNamed(
                          StoreItemsScreen.routeName,
                          extra: (
                            merchantId: _merchantId,
                            merchantName: _merchantName,
                            categoryName: null,
                          ),
                        );
                      },
                      child: const Text("Browse Services"),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final s = favorites[i];
              return _FavouriteCard(
                service: s,
                onToggle: () {
                  setState(() {
                    if (_favoriteIds.contains(s.merchantServiceID)) {
                      _favoriteIds.remove(s.merchantServiceID);
                    } else {
                      _favoriteIds.add(s.merchantServiceID);
                    }
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}

class SavedAddressesScreen extends StatefulWidget {
  static String routeName = "SavedAddresses";
  static String route = "/SavedAddresses";
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  final _api = dpLocator<ServanaApiClient>();
  List<Map<String, dynamic>> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.getAllUserAddresses();
      final raw = res['data'] ?? res['items'] ?? res;
      if (raw is List) {
        _addresses = raw.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: ColorPalette.secondaryText,
          ),
        ),
        title: Text(
          "Saved Addresses",
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: ColorPalette.secondaryText,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _onAddAddress,
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: ColorPalette.primaryColorDark,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_off_rounded,
                          size: 48, color: ColorPalette.accentText),
                      const SizedBox(height: 12),
                      Text(
                        "No saved addresses yet",
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          color: ColorPalette.secondaryText.withOpacity(.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _onAddAddress,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Address'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorPalette.primaryColorDark,
                          foregroundColor: ColorPalette.primaryText,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAddresses,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _addresses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final addr = _addresses[i];
                      final addrId =
                          (addr['addressId'] ?? addr['id'] ?? '').toString();
                      return _SavedAddressCard(
                        address: _SavedAddress(
                          id: addrId,
                          label: (addr['label'] ?? '').toString(),
                          addressLine: (addr['addressOne'] ?? '').toString(),
                          cityLine: (addr['postTown'] ?? '').toString(),
                          note: (addr['addressTwo'] ?? '').toString(),
                          isDefault: addr['isPrimary'] == true,
                        ),
                        onSetDefault: () => _setDefault(addrId),
                        onEdit: () => _onEditAddress(addr),
                        onDelete: () => _onDeleteAddress(addrId),
                      );
                    },
                  ),
                ),
    );
  }

  Future<void> _onAddAddress() async {
    final result = await Navigator.of(context).push<AddressFormResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const AddressFormScreen(
          title: 'Add Address',
          actionLabel: 'Save Address',
          showGps: true,
        ),
      ),
    );
    if (result == null || !mounted) return;

    try {
      final session = await SessionService.getSession();
      final userId = session?.customerID ?? '';
      final lat = result.location.latitude;
      final lon = result.location.longitude;

      await _api.addUserAddress(payload: {
        'userId': userId,
        'locationId': 'loc_${lat.toStringAsFixed(6)}_${lon.toStringAsFixed(6)}',
        'addressOne': result.address,
        'addressTwo':
            [result.unit, result.street].where((s) => s.isNotEmpty).join(', '),
        'zipCode': '',
        'postTown': result.city.isNotEmpty ? result.city : result.province,
        'country': 'Philippines',
        'lat': lat,
        'lon': lon,
        'label': result.landmark.isNotEmpty
            ? result.landmark
            : (result.barangay.isNotEmpty ? result.barangay : 'Home'),
        'isPrimary': _addresses.isEmpty,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address saved!')),
      );
      await _loadAddresses();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save address: $e')),
      );
    }
  }

  Future<void> _onEditAddress(Map<String, dynamic> existing) async {
    final addrId = (existing['addressId'] ?? existing['id'] ?? '').toString();
    final oldLat = (existing['lat'] as num?)?.toDouble() ?? 0.0;
    final oldLon = (existing['lon'] as num?)?.toDouble() ?? 0.0;

    final result = await Navigator.of(context).push<AddressFormResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AddressFormScreen(
          title: 'Edit Address',
          actionLabel: 'Save Changes',
          initialAddress: (existing['addressOne'] ?? '').toString(),
          initialCity: (existing['postTown'] ?? '').toString(),
          initialLandmark: (existing['label'] ?? '').toString(),
          initialLocation:
              (oldLat != 0 || oldLon != 0) ? LatLong(oldLat, oldLon) : null,
          showGps: true,
        ),
      ),
    );
    if (result == null || !mounted) return;

    try {
      final session = await SessionService.getSession();
      final userId = session?.customerID ?? '';
      final lat = result.location.latitude;
      final lon = result.location.longitude;
      final useLat = (lat == 0 && lon == 0) ? oldLat : lat;
      final useLon = (lat == 0 && lon == 0) ? oldLon : lon;
      final wasPrimary = existing['isPrimary'] == true;

      // Delete the old address, then create the updated one
      await _api.deleteAddress(addressId: addrId);
      await _api.addUserAddress(payload: {
        'userId': userId,
        'locationId':
            'loc_${useLat.toStringAsFixed(6)}_${useLon.toStringAsFixed(6)}',
        'addressOne': result.address,
        'addressTwo':
            [result.unit, result.street].where((s) => s.isNotEmpty).join(', '),
        'zipCode': '',
        'postTown': result.city.isNotEmpty ? result.city : result.province,
        'country': (existing['country'] ?? 'Philippines').toString(),
        'lat': useLat,
        'lon': useLon,
        'label': result.landmark.isNotEmpty
            ? result.landmark
            : (result.barangay.isNotEmpty ? result.barangay : 'Home'),
        'isPrimary': wasPrimary,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address updated!')),
      );
      await _loadAddresses();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update address: $e')),
      );
    }
  }

  Future<void> _setDefault(String addressId) async {
    try {
      await _api.makeAddressPrimary(addressId: addressId);
      await _loadAddresses();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set default: $e')),
      );
    }
  }

  Future<void> _onDeleteAddress(String addressId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: ColorPalette.danger)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _api.deleteAddress(addressId: addressId);
      await _loadAddresses();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }
}

class SettingsScreen extends StatelessWidget {
  static String routeName = "Settings";
  static String route = "/Settings";
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DrawerPlaceholderScreen(title: "Settings");
  }
}

class LanguageScreen extends StatefulWidget {
  static String routeName = "Language";
  static String route = "/Language";
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selected = 'English';

  final List<_LanguageOption> _options = const [
    _LanguageOption('English', 'EN'),
    _LanguageOption('Filipino', 'FIL'),
    _LanguageOption('Cebuano', 'CEB'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: ColorPalette.secondaryText,
          ),
        ),
        title: Text(
          "Language",
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: ColorPalette.secondaryText,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "Choose your preferred language",
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              color: ColorPalette.secondaryText.withOpacity(.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ..._options.map((option) {
            final isSelected = option.name == _selected;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selected = option.name;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ColorPalette.secondaryBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? ColorPalette.primaryColorDark
                          : ColorPalette.border(.55),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? ColorPalette.primaryColorDark.withOpacity(.15)
                              : ColorPalette.primaryColor.withOpacity(.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            option.code,
                            style: TextStyle(
                              fontFamily: FontPalette.primaryFontFamily,
                              fontWeight: FontWeight.w700,
                              color: ColorPalette.primaryColorDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option.name,
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontWeight: FontWeight.w700,
                            color: ColorPalette.secondaryText,
                          ),
                        ),
                      ),
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: isSelected
                            ? ColorPalette.primaryColorDark
                            : ColorPalette.secondaryText.withOpacity(.4),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(
            "Language changes will take effect the next time you open the app.",
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              color: ColorPalette.secondaryText.withOpacity(.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class HelpSupportScreen extends StatefulWidget {
  static String routeName = "HelpSupport";
  static String route = "/HelpSupport";
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  int? _expanded;

  static const _faqs = [
    _Faq(
      q: 'How do I cancel a booking?',
      a: 'Open your booking from the Bookings tab and tap "Cancel Booking" at the bottom of the detail screen. '
          'Cancellations must be made at least 2 hours before the scheduled time.',
    ),
    _Faq(
      q: 'How is payment processed?',
      a: 'Payments are handled securely via PayMongo. '
          'You will be redirected to a payment page after your booking is confirmed. '
          'Servana never stores your card details.',
    ),
    _Faq(
      q: 'What happens if a provider does not show up?',
      a: 'If your provider is more than 30 minutes late or does not arrive, '
          'contact our support team immediately via the chat below. '
          'We will rebook or refund you within 24 hours.',
    ),
    _Faq(
      q: 'Can I reschedule a booking?',
      a: 'Rescheduling is currently handled by our support team. '
          'Please reach out via the Contact Support option and include your booking number.',
    ),
    _Faq(
      q: 'How do I update my address?',
      a: 'Go to Profile → Saved Addresses to add, edit, or remove addresses. '
          'You can also set a default address for quicker checkout.',
    ),
    _Faq(
      q: 'Is my personal information safe?',
      a: 'Yes. Servana uses industry-standard encryption for all data in transit and at rest. '
          'We do not sell or share your personal information with third parties.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: ColorPalette.secondaryText,
          ),
        ),
        title: Text(
          'Help & Support',
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: ColorPalette.secondaryText,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Frequently asked questions',
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: ColorPalette.secondaryText,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_faqs.length, (i) {
            final faq = _faqs[i];
            final open = _expanded == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: ColorPalette.secondaryBackground,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () =>
                      setState(() => _expanded = open ? null : i),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                faq.q,
                                style: TextStyle(
                                  fontFamily: FontPalette.primaryFontFamily,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: ColorPalette.secondaryText,
                                ),
                              ),
                            ),
                            Icon(
                              open
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: ColorPalette.secondaryText
                                  .withOpacity(.45),
                              size: 20,
                            ),
                          ],
                        ),
                        if (open) ...[
                          const SizedBox(height: 10),
                          Text(
                            faq.a,
                            style: TextStyle(
                              fontFamily: FontPalette.primaryFontFamily,
                              fontSize: 13,
                              color: ColorPalette.secondaryText.withOpacity(.75),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          Text(
            'Still need help?',
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: ColorPalette.secondaryText,
            ),
          ),
          const SizedBox(height: 10),
          Semantics(
            button: true,
            label: 'Contact Support via email',
            child: Material(
              color: ColorPalette.primaryColorDark.withOpacity(.07),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: ColorPalette.primaryColorDark,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.email_outlined,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contact Support',
                              style: TextStyle(
                                fontFamily: FontPalette.primaryFontFamily,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: ColorPalette.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'support@servana.com.ph',
                              style: TextStyle(
                                fontFamily: FontPalette.primaryFontFamily,
                                fontSize: 12,
                                color: ColorPalette.secondaryText
                                    .withOpacity(.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: ColorPalette.secondaryText.withOpacity(.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Faq {
  const _Faq({required this.q, required this.a});
  final String q;
  final String a;
}

class _DrawerPlaceholderScreen extends StatelessWidget {
  const _DrawerPlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: ColorPalette.secondaryText,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: ColorPalette.secondaryText,
          ),
        ),
      ),
      body: Center(
        child: Text(
          "$title screen",
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            color: ColorPalette.secondaryText.withOpacity(.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _LanguageOption {
  const _LanguageOption(this.name, this.code);
  final String name;
  final String code;
}

class _RewardItem {
  const _RewardItem({
    required this.title,
    required this.description,
    required this.cost,
  });

  final String title;
  final String description;
  final int cost;
}

class _RewardsBalanceCard extends StatelessWidget {
  const _RewardsBalanceCard({
    required this.points,
    required this.progress,
  });

  final int points;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorPalette.primaryColorDark,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: ColorPalette.shadow(.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Total Points",
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              color: ColorPalette.primaryText.withOpacity(.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "$points",
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              color: ColorPalette.primaryText,
              fontWeight: FontWeight.w800,
              fontSize: 30,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: ColorPalette.primaryText.withOpacity(.15),
              valueColor: AlwaysStoppedAnimation(
                  ColorPalette.primaryColor.withOpacity(.9)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Next tier in ${(2000 - points).clamp(0, 2000)} pts",
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              color: ColorPalette.primaryText.withOpacity(.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardItemCard extends StatelessWidget {
  const _RewardItemCard({
    required this.item,
    required this.canRedeem,
    required this.onRedeem,
  });

  final _RewardItem item;
  final bool canRedeem;
  final VoidCallback? onRedeem;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColorPalette.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorPalette.border(.55)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ColorPalette.primaryColor.withOpacity(.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.card_giftcard_rounded,
              color: ColorPalette.primaryColorDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.w700,
                    color: ColorPalette.secondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 12,
                    color: ColorPalette.secondaryText.withOpacity(.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${item.cost} pts",
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontWeight: FontWeight.w700,
                  color: ColorPalette.primaryColorDark,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: onRedeem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canRedeem
                        ? ColorPalette.primaryColorDark
                        : ColorPalette.primaryColorDark.withOpacity(.35),
                    foregroundColor: ColorPalette.primaryButtonTextColor,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "Redeem",
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardHistoryTile extends StatelessWidget {
  const _RewardHistoryTile({
    required this.title,
    required this.subtitle,
    required this.points,
  });

  final String title;
  final String subtitle;
  final int points;

  @override
  Widget build(BuildContext context) {
    final isEarned = points >= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ColorPalette.secondaryBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ColorPalette.border(.55)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (isEarned
                        ? ColorPalette.primaryColor
                        : ColorPalette.accentText)
                    .withOpacity(.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isEarned ? Icons.stars_rounded : Icons.redeem_rounded,
                color: ColorPalette.primaryColorDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontWeight: FontWeight.w700,
                      color: ColorPalette.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 12,
                      color: ColorPalette.secondaryText.withOpacity(.7),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "${isEarned ? '+' : ''}$points",
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontWeight: FontWeight.w700,
                color: isEarned
                    ? ColorPalette.primaryColorDark
                    : ColorPalette.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedAddress {
  const _SavedAddress({
    this.id = '',
    required this.label,
    required this.addressLine,
    required this.cityLine,
    required this.note,
    required this.isDefault,
  });

  final String id;
  final String label;
  final String addressLine;
  final String cityLine;
  final String note;
  final bool isDefault;
}

class _SavedAddressCard extends StatelessWidget {
  const _SavedAddressCard({
    required this.address,
    required this.onSetDefault,
    required this.onEdit,
    required this.onDelete,
  });

  final _SavedAddress address;
  final VoidCallback onSetDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColorPalette.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorPalette.border(.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ColorPalette.primaryColor.withOpacity(.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: ColorPalette.primaryColorDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      address.label,
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w700,
                        color: ColorPalette.secondaryText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (address.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: ColorPalette.primaryColor.withOpacity(.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "Default",
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: ColorPalette.primaryColorDark,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  address.addressLine,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    color: ColorPalette.secondaryText.withOpacity(.8),
                  ),
                ),
                Text(
                  address.cityLine,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    color: ColorPalette.secondaryText.withOpacity(.7),
                    fontSize: 12,
                  ),
                ),
                if (address.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    address.note,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      color: ColorPalette.secondaryText.withOpacity(.6),
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: onSetDefault,
                      child: const Text("Set default"),
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: onEdit,
                      child: const Text("Edit"),
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: onDelete,
                      child: const Text("Delete"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FavouriteCard extends StatelessWidget {
  const _FavouriteCard({
    required this.service,
    required this.onToggle,
  });

  final MerchantServiceModel service;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorPalette.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorPalette.border(.55)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AppImage(
              url: service.merchantServicePictureURL,
              height: 56,
              width: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.merchantServiceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.w700,
                    color: ColorPalette.secondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service.merchantServiceDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 12,
                    color: ColorPalette.secondaryText.withOpacity(.65),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "₱${service.amount}",
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.w700,
                    color: ColorPalette.primaryColorDark,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onToggle,
            icon: Icon(
              Icons.favorite_rounded,
              color: ColorPalette.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
