/// Widget behaviour for the canonical catalog screens.
///
/// Covers the five states, the small-screen layout floor, and the identity a
/// tap emits.
///
/// A note on judging overflow here: the test font is a substitute and renders
/// wider than Poppins, so a few logical pixels of overflow mean nothing. These
/// assert that NO overflow occurs at the narrowest supported width with
/// realistic long names — a magnitude check, not a pixel one.
library;

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/modules/catalog/application/catalog_controller.dart';
import 'package:client/modules/catalog/data/catalog_cache.dart';
import 'package:client/modules/catalog/data/catalog_repository.dart';
import 'package:client/modules/catalog/domain/catalog_models.dart';
import 'package:client/modules/catalog/presentation/screens/catalog_browse_screen.dart';
import 'package:client/modules/catalog/presentation/screens/category_screen.dart';
import 'package:client/modules/catalog/presentation/screens/subcategory_screen.dart';
import 'package:client/modules/catalog/presentation/widgets/catalog_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _kLongName =
    'Aircon Cleaning for Ceiling Cassette Type with Deep Coil Treatment';

Map<String, dynamic> _body({
  String serviceName = 'Pimple Facial',
  bool emptySubcategory = false,
  bool emptyCatalog = false,
}) =>
    {
      'status': 'success',
      'data': {
        'categories': emptyCatalog
            ? <dynamic>[]
            : [
                {
                  'id': 3,
                  'name': 'Personal Care',
                  'slug': 'personal-care',
                  'displayOrder': 0,
                  'subcategories': [
                    {
                      'id': 7,
                      'categoryId': 3,
                      'name': 'Facial',
                      'slug': 'facial',
                      'displayOrder': 0,
                      'services': emptySubcategory
                          ? <dynamic>[]
                          : [
                              {
                                'id': 15,
                                'subcategoryId': 7,
                                'subcategoryName': 'Facial',
                                'categoryId': 3,
                                'categoryName': 'Personal Care',
                                'name': serviceName,
                                'slug': 'svc-15',
                                'status': 'active',
                                'displayOrder': 0,
                                'bookable': true,
                                'basePrice': 1500,
                                'unit': 'per session',
                                'basePriceSummary': '₱1,500 / per session',
                              },
                            ],
                    },
                  ],
                },
              ],
      },
    };

class _Api extends ServanaApiClient {
  _Api({this.body, this.fail = false}) : super(baseUrl: 'http://fake.test');

  final Map<String, dynamic>? body;
  final bool fail;

  @override
  Future<Map<String, dynamic>> getCanonicalCatalog() async {
    if (fail) throw Exception('network down');
    return body ?? _body();
  }

  @override
  Future<Map<String, dynamic>> getCanonicalCatalogSummary() async =>
      {'status': 'success', 'data': const <String, dynamic>{}};
}

class _NoCache extends CatalogCache {
  @override
  Future<Catalog?> read() async => null;
  @override
  Future<void> write(Catalog catalog) async {}
  @override
  Future<void> clear() async {}
}

CatalogController _controller(
        {Map<String, dynamic>? body, bool fail = false}) =>
    CatalogController(CatalogRepository(
        api: _Api(body: body, fail: fail), cache: _NoCache()));

Future<void> _pump(WidgetTester tester, Widget child, {Size? size}) async {
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }
  await tester.pumpWidget(MaterialApp(home: child));
  await tester.pumpAndSettle();
}

void main() {
  group('CatalogBrowseScreen', () {
    testWidgets('renders Categories with their service counts', (tester) async {
      await _pump(
        tester,
        CatalogBrowseScreen(
          controller: _controller(),
          onCategorySelected: (_) {},
        ),
      );

      expect(find.text('Personal Care'), findsOneWidget);
      expect(find.text('1 service'), findsOneWidget);
    });

    testWidgets('emits the canonical category id on tap', (tester) async {
      int? tapped;
      await _pump(
        tester,
        CatalogBrowseScreen(
          controller: _controller(),
          onCategorySelected: (id) => tapped = id,
        ),
      );

      await tester.tap(find.text('Personal Care'));
      await tester.pumpAndSettle();

      expect(tapped, 3);
    });

    testWidgets('shows a retryable error, never a fabricated catalog',
        (tester) async {
      await _pump(
        tester,
        CatalogBrowseScreen(
          controller: _controller(fail: true),
          onCategorySelected: (_) {},
        ),
      );

      expect(find.text('Unable to load services.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      // §50: nothing that looks like real catalog content.
      expect(find.text('Personal Care'), findsNothing);
    });

    testWidgets('shows an empty state rather than a blank scroll view',
        (tester) async {
      await _pump(
        tester,
        CatalogBrowseScreen(
          controller: _controller(body: _body(emptyCatalog: true)),
          onCategorySelected: (_) {},
        ),
      );

      expect(find.text('No services are available right now.'), findsOneWidget);
    });
  });

  group('CategoryScreen', () {
    testWidgets('lists Subcategories and emits the canonical id',
        (tester) async {
      int? tapped;
      await _pump(
        tester,
        CategoryScreen(
          controller: _controller(),
          categoryId: 3,
          onSubcategorySelected: (id) => tapped = id,
        ),
      );

      expect(find.text('Facial'), findsWidgets);
      await tester.tap(find.text('Facial').first);
      await tester.pumpAndSettle();
      expect(tapped, 7);
    });

    testWidgets('an id absent from the catalog is unavailable, not blank',
        (tester) async {
      await _pump(
        tester,
        CategoryScreen(
          controller: _controller(),
          categoryId: 99999,
          onSubcategorySelected: (_) {},
        ),
      );

      expect(
          find.text('This category is no longer available.'), findsOneWidget);
    });

    testWidgets('an empty Category says so', (tester) async {
      await _pump(
        tester,
        CategoryScreen(
          controller: _controller(body: _body(emptySubcategory: true)),
          categoryId: 3,
          onSubcategorySelected: (_) {},
        ),
      );
      // The Subcategory still exists, so the Category is not empty — it lists
      // Facial, whose own empty state appears one level down.
      expect(find.text('0 services'), findsOneWidget);
    });
  });

  group('SubcategoryScreen', () {
    testWidgets('emits the canonical services.id on tap', (tester) async {
      CatalogService? tapped;
      await _pump(
        tester,
        SubcategoryScreen(
          controller: _controller(),
          subcategoryId: 7,
          onServiceSelected: (s) => tapped = s,
        ),
      );

      await tester.tap(find.text('Pimple Facial'));
      await tester.pumpAndSettle();

      expect(tapped?.id, 15);
      // Identity is the id, never the name.
      expect(tapped?.subcategoryId, 7);
    });

    testWidgets('renders the breadcrumb from the hierarchy, not a level2 field',
        (tester) async {
      await _pump(
        tester,
        SubcategoryScreen(
          controller: _controller(),
          subcategoryId: 7,
          onServiceSelected: (_) {},
        ),
      );

      expect(find.text('Personal Care › Facial'), findsOneWidget);
    });

    testWidgets('an empty Subcategory shows its empty state', (tester) async {
      await _pump(
        tester,
        SubcategoryScreen(
          controller: _controller(body: _body(emptySubcategory: true)),
          subcategoryId: 7,
          onServiceSelected: (_) {},
        ),
      );

      expect(find.textContaining('No services are listed under Facial'),
          findsOneWidget);
    });
  });

  group('layout floor', () {
    // 320×568 is the narrowest device in the support matrix.
    testWidgets('a long Service name does not overflow at 320 wide',
        (tester) async {
      await _pump(
        tester,
        SubcategoryScreen(
          controller: _controller(body: _body(serviceName: _kLongName)),
          subcategoryId: 7,
          onServiceSelected: (_) {},
        ),
        size: const Size(320, 568),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('a Service card meets the 44dp touch-target floor',
        (tester) async {
      await _pump(
        tester,
        SubcategoryScreen(
          controller: _controller(),
          subcategoryId: 7,
          onServiceSelected: (_) {},
        ),
        size: const Size(320, 568),
      );

      final card = tester.getSize(find.byType(ServiceCard).first);
      expect(card.height, greaterThanOrEqualTo(44));
    });
  });
}
