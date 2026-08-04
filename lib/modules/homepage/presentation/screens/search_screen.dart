import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/domain/services/service_category_config.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/presentation/screens/notifications_screen.dart';
import 'package:client/modules/aircon_booking/presentation/screens/aircon_options_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/bw_options_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/hair_nails_screen.dart';
import 'package:client/modules/bw_booking/presentation/screens/massage_screen.dart';
import 'package:client/modules/search/application/search_controller.dart';
import 'package:client/modules/search/application/search_sort.dart';
import 'package:client/modules/search/domain/search_result.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:go_router/go_router.dart';

class _ChipData {
  const _ChipData(this.id, this.label);
  final ServiceCategoryId id;
  final String label;
}

class SearchScreen extends StatefulWidget {
  static String routeName = "SearchScreen";
  static String route = "SearchScreen";

  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final SearchController _ctrl;
  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  static const _kChips = [
    _ChipData(ServiceCategoryId.aircon, 'Aircon'),
    _ChipData(ServiceCategoryId.beautyWellness, 'Beauty & Wellness'),
    _ChipData(ServiceCategoryId.hairAndNails, 'Hair & Nails'),
    _ChipData(ServiceCategoryId.massage, 'Massage'),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = dpLocator<SearchController>();
    _ctrl.init();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onResultTap(SearchResult result) {
    switch (result.categoryId) {
      case ServiceCategoryId.aircon:
        context.pushNamed(AirconOptionsScreen.routeName);
      case ServiceCategoryId.beautyWellness:
        context.pushNamed(BwOptionsScreen.routeName);
      case ServiceCategoryId.hairAndNails:
        context.pushNamed(HairNailsScreen.routeName);
      case ServiceCategoryId.massage:
        context.pushNamed(MassageScreen.routeName);
      case ServiceCategoryId.generic:
        break;
    }
  }

  void _clearQuery() {
    _textCtrl.clear();
    _ctrl.clearQuery();
    _focusNode.requestFocus();
  }

  void _selectHistory(String term) {
    _textCtrl.text = term;
    _textCtrl.selection = TextSelection.collapsed(offset: term.length);
    _ctrl.selectHistory(term);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ctrl,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: ColorPalette.primaryBackground,
          body: Column(
            children: [
              _buildHeader(context),
              Expanded(child: _buildBody()),
            ],
          ),
        );
      },
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
              Semantics(
                label: 'Go back',
                button: true,
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  behavior: HitTestBehavior.opaque,
                  child: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 26),
                ),
              ),
              Expanded(
                child: Text(
                  'Search',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              Semantics(
                label: 'View notifications',
                button: true,
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => context.pushNamed(NotificationsScreen.routeName),
                  behavior: HitTestBehavior.opaque,
                  child: const Icon(Icons.notifications_outlined,
                      color: Colors.white, size: 26),
                ),
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
                    controller: _textCtrl,
                    focusNode: _focusNode,
                    autofocus: true,
                    onChanged: _ctrl.onQueryChanged,
                    onSubmitted: (v) {
                      _ctrl.onQuerySubmitted(v);
                      _focusNode.unfocus();
                    },
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
                      hintText: 'Search for services you need',
                      hintStyle: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontSize: 14,
                        color: ColorPalette.secondaryText.withOpacity(0.45),
                      ),
                    ),
                  ),
                ),
                if (_ctrl.hasQuery)
                  GestureDetector(
                    onTap: _clearQuery,
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

  Widget _buildBody() => switch (_ctrl.state) {
        SearchLoadState.idle || SearchLoadState.loading => _buildLoading(),
        SearchLoadState.error => _buildError(),
        SearchLoadState.ready =>
          _ctrl.hasQuery ? _buildResults() : _buildDiscovery(),
      };

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_outlined,
                size: 48, color: ColorPalette.secondaryText.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(
              'Could not load services. Check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                color: ColorPalette.secondaryText,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _ctrl.refresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscovery() {
    return CustomScrollView(
      slivers: [
        if (_ctrl.history.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent searches',
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: ColorPalette.secondaryText,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      for (final t in List<String>.from(_ctrl.history)) {
                        _ctrl.removeHistory(t);
                      }
                    },
                    child: Text(
                      'Clear all',
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontSize: 13,
                        color: ColorPalette.primaryColorDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final term = _ctrl.history[i];
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.history,
                      size: 18,
                      color: ColorPalette.secondaryText.withOpacity(0.5)),
                  title: Text(
                    term,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 14,
                      color: ColorPalette.secondaryText,
                    ),
                  ),
                  trailing: Semantics(
                    label: 'Remove "$term" from history',
                    button: true,
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: () => _ctrl.removeHistory(term),
                      child: Icon(Icons.close,
                          size: 16,
                          color: ColorPalette.secondaryText.withOpacity(0.4)),
                    ),
                  ),
                  onTap: () => _selectHistory(term),
                );
              },
              childCount: _ctrl.history.length,
            ),
          ),
        ],
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              'Browse by category',
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: ColorPalette.secondaryText,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kChips.map((chip) {
                return GestureDetector(
                  onTap: () {
                    _textCtrl.text = chip.label;
                    _ctrl.onQueryChanged(chip.label);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black.withOpacity(0.08)),
                    ),
                    child: Text(
                      chip.label,
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: ColorPalette.secondaryText,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildResults() {
    return Column(
      children: [
        _buildFiltersRow(),
        Expanded(
          child: _ctrl.isEmpty ? _buildEmpty() : _buildResultsGrid(),
        ),
      ],
    );
  }

  Widget _buildFiltersRow() {
    return Container(
      color: ColorPalette.primaryBackground,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                // A BoxScrollView with `padding: null` adopts MediaQuery
                // padding. Horizontal, that means the left/right device insets
                // — zero in portrait, non-zero in landscape on a cutout
                // device, where the chip row would gain a phantom leading gap.
                // Same defect the Home category grid had vertically.
                padding: EdgeInsets.zero,
                scrollDirection: Axis.horizontal,
                itemCount: _kChips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final chip = _kChips[i];
                  final selected = _ctrl.categoryFilter == chip.id;
                  return Semantics(
                    label: chip.label,
                    button: true,
                    selected: selected,
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: () => _ctrl.setCategoryFilter(chip.id),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? ColorPalette.primaryColorDark
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? ColorPalette.primaryColorDark
                                : Colors.black.withOpacity(0.08),
                          ),
                        ),
                        child: Text(
                          chip.label,
                          style: TextStyle(
                            fontFamily: FontPalette.primaryFontFamily,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: selected
                                ? Colors.white
                                : ColorPalette.secondaryText,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            label: 'Sort results',
            button: true,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => _showSortSheet(context),
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.sort,
                        size: 16, color: ColorPalette.secondaryText),
                    const SizedBox(width: 4),
                    Text(
                      'Sort',
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: ColorPalette.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
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
              'No services match your search.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                color: ColorPalette.secondaryText.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _clearQuery,
              child: Text(
                'Clear search',
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.primaryColorDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsGrid() {
    final results = _ctrl.results;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => SearchResultCard(
                result: results[i],
                onTap: () => _onResultTap(results[i]),
              ),
              childCount: results.length,
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

  Future<void> _showSortSheet(BuildContext context) async {
    final current = _ctrl.sort;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sort by',
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: ColorPalette.secondaryText,
              ),
            ),
            const SizedBox(height: 8),
            ...SearchSort.values.map(
              (s) => ListTile(
                dense: true,
                title: Text(
                  s.label,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 15,
                    color: ColorPalette.secondaryText,
                    fontWeight:
                        s == current ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                trailing: s == current
                    ? Icon(Icons.check,
                        color: ColorPalette.primaryColorDark, size: 20)
                    : null,
                onTap: () {
                  _ctrl.setSort(s);
                  Navigator.of(ctx).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single search result tile.
///
/// Public, and named without an underscore, so `test/homepage/
/// search_result_card_overflow_test.dart` can render the REAL widget at real
/// grid-tile sizes. It was private, and the overflow test had to pump a
/// hand-written copy of its layout instead — which passed against the broken
/// production card, because a copy only ever tests the copy.
@visibleForTesting
class SearchResultCard extends StatelessWidget {
  const SearchResultCard(
      {super.key, required this.result, required this.onTap});

  final SearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: result.level2,
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
                // The image absorbs the slack, and gives it back when the text
                // needs more room.
                //
                // This was `AspectRatio(aspectRatio: 1)` — a hard square whose
                // height is the card's full width. The tile height comes from
                // `childAspectRatio: 0.72`, so a square image plus the text
                // below it does not fit: every card overflowed by 0.556px on a
                // Pixel 8, and by ~24px on a 360-wide phone at 1.3x text scale,
                // where it is a visibly clipped card rather than a debug stripe.
                //
                // `Expanded` inverts the relationship: the text block takes the
                // height it needs and the image takes whatever is left. With
                // BoxFit.cover the artwork still fills its box, so it reads the
                // same at normal scale and simply gets shorter when the text
                // grows. Wrapping the AspectRatio in Flexible was the other
                // option and was rejected — it keeps the square by shrinking
                // the image's WIDTH, leaving dead space beside it.
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: double.infinity,
                      child: Image.asset(
                        result.imageAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFEEF2FF),
                          child: Icon(Icons.home_repair_service,
                              color: ColorPalette.primaryColorDark, size: 36),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.level2,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: ColorPalette.secondaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  result.priceDisplay,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: ColorPalette.primaryColorDark,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ColorPalette.primaryColorDark.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    result.categoryLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 11,
                      color: ColorPalette.primaryColorDark,
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
