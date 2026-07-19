import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/presentation/screens/notifications_screen.dart';
import 'package:client/common/presentation/widgets/service_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Reusable service-listing scaffold matching Figma node 596:3833.
///
/// Renders a blue header with a search bar + filter chips, then a 2-column grid
/// of service cards. Used by Beauty, Hair & Nails, Massage, and Aircon Repair.
///
/// The host screen is responsible for loading data, transforming it into
/// [ServiceCardModel]s, and reacting to taps via [onCardTap]. Filter chips
/// match against [ServiceCardModel.categoryKey] (case-insensitive substring).
class ServiceCategoryListScreen extends StatefulWidget {
  const ServiceCategoryListScreen({
    super.key,
    required this.title,
    required this.filterChips,
    required this.items,
    required this.onCardTap,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  final String title;
  final List<String> filterChips;
  final List<ServiceCardModel> items;
  final void Function(BuildContext, ServiceCardModel) onCardTap;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  State<ServiceCategoryListScreen> createState() =>
      _ServiceCategoryListScreenState();
}

class _ServiceCategoryListScreenState extends State<ServiceCategoryListScreen> {
  int _selectedChip = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ServiceCardModel> get _filteredItems {
    Iterable<ServiceCardModel> result = widget.items;
    if (_selectedChip != 0) {
      final needle = widget.filterChips[_selectedChip].toLowerCase();
      result = result
          .where((item) => item.categoryKey.toLowerCase().contains(needle));
    }
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((item) => item.name.toLowerCase().contains(query));
    }
    return result.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      body: Column(
        children: [
          _buildHeader(context),
          _buildChipsRow(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 20,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ColorPalette.primaryColorDark,
            ColorPalette.primaryGradientEnd(),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                behavior: HitTestBehavior.opaque,
                child:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 26),
              ),
              Expanded(
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.pushNamed(NotificationsScreen.routeName),
                behavior: HitTestBehavior.opaque,
                child: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 51,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.search,
                    color: ColorPalette.primaryColorDark, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    textInputAction: TextInputAction.search,
                    cursorColor: ColorPalette.primaryColorDark,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 14,
                      color: ColorPalette.secondaryText,
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      hintText: 'Search for services you need',
                      hintStyle: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontSize: 14,
                        color: ColorPalette.secondaryText.withOpacity(0.45),
                      ),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.close,
                          color: ColorPalette.secondaryText.withOpacity(0.5),
                          size: 18),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipsRow() {
    return Container(
      color: ColorPalette.primaryBackground,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: widget.filterChips.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final selected = i == _selectedChip;
            return GestureDetector(
              onTap: () => setState(() => _selectedChip = i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      selected ? ColorPalette.primaryColorDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? ColorPalette.primaryColorDark
                        : Colors.black.withOpacity(0.08),
                  ),
                ),
                child: Text(
                  widget.filterChips[i],
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: selected ? Colors.white : ColorPalette.secondaryText,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (widget.isLoading && widget.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.errorMessage != null && widget.items.isEmpty) {
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
                widget.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  color: ColorPalette.secondaryText,
                ),
              ),
              if (widget.onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                    onPressed: widget.onRetry, child: const Text('Retry')),
              ],
            ],
          ),
        ),
      );
    }

    final items = _filteredItems;
    if (items.isEmpty) {
      final hasFilter = _searchQuery.trim().isNotEmpty || _selectedChip != 0;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/states/end_of_list.png',
                width: 180,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              Text(
                hasFilter
                    ? 'No services match your search.'
                    : 'No services available.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  color: ColorPalette.secondaryText.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final item = items[i];
                return _ServiceCard(
                  item: item,
                  onTap: () => widget.onCardTap(context, item),
                );
              },
              childCount: items.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Center(
              child: Image.asset(
                'assets/images/states/end_of_list.png',
                width: 160,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Lightweight VM for a single card. Hosts pass these in; the screen does
/// not know about MobX/BLoC.
///
/// `raw` is `Object?` rather than `dynamic` so callers explicitly cast at the
/// boundary in `onCardTap` — this catches type drift between hosts at compile
/// time. Different hosts use different shapes (option Maps, source-tagged
/// wrappers); the cast belongs at each call site.
class ServiceCardModel {
  ServiceCardModel({
    required this.raw,
    required this.name,
    this.categoryKey = '',
    this.price = 0,
    String? imageAsset,
  }) : imageAsset = imageAsset ?? serviceImageAsset(name);

  final Object? raw;
  final String name;
  final String categoryKey;
  final int price;
  final String imageAsset;

  /// Pulls a price out of an options-with-addons option Map. The live API
  /// ships `basePrice` as a *string* (e.g. "3500"); tolerate num too in case
  /// the shape changes. Returns 0 when no price field is present.
  static int extractPrice(Map<String, dynamic> raw) {
    final v =
        raw['basePrice'] ?? raw['base_price'] ?? raw['price'] ?? raw['amount'];
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  /// Renders a price (num or stringified num) without a trailing ".00" when
  /// it's a whole number. Used by every booking screen that shows option /
  /// add-on prices inline.
  static String formatPrice(dynamic v) {
    if (v is num) return v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2);
    return v.toString();
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.item, required this.onTap});

  final ServiceCardModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: item.name,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.08),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(item.imageAsset, fit: BoxFit.cover),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: ColorPalette.secondaryText,
                          ),
                        ),
                        if (item.price > 0)
                          Text(
                            '₱${item.price}',
                            style: TextStyle(
                              fontFamily: FontPalette.primaryFontFamily,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: ColorPalette.primaryColorDark,
                            ),
                          ),
                      ],
                    ),
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
