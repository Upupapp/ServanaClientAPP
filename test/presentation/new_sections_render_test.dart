/// The two sections this sweep added, rendered with real data.
///
/// Both were written to draw NOTHING when there is nothing to show — Home's
/// extra categories when the catalog adds none, booking detail's change orders
/// when the booking has none, which is almost every booking. That is the right
/// default and it is also the state every other test in this repo exercises,
/// so without this file the populated case ships unseen.
///
/// These render the populated case at every viewport and text scale the app
/// declares it supports, and assert the content is actually on screen rather
/// than only that nothing threw.
library;

import 'package:client/common/constants/color_palette.dart';
import 'package:client/modules/booking_experiences/application/booking_experiences_controller.dart';
import 'package:client/modules/booking_experiences/domain/additional_work.dart';
import 'package:client/modules/booking_experiences/presentation/widgets/change_orders_section.dart';
import 'package:client/modules/homepage/application/home_composition_controller.dart';
import 'package:client/modules/homepage/presentation/widgets/home_more_categories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Map<String, Size> _viewports = <String, Size>{
  '320x568': Size(320, 568),
  '360x640': Size(360, 640),
  '390x844': Size(390, 844),
};

const List<double> _scales = <double>[1.0, 1.3, 2.0];

Future<void> render(
    WidgetTester tester, Widget child, Size size, double scale) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
      child: MaterialApp(
        home: Scaffold(
          backgroundColor: ColorPalette.primaryBackground,
          // Scrollable so a section taller than the viewport is a scroll and
          // not an overflow — which is what both of these sit inside in the
          // real screens.
          body: SingleChildScrollView(child: child),
        ),
      ),
    ),
  );
}

void main() {
  group('Home — More services', () {
    const catalogOnly = HomeCategoriesReady(
      <HomeCategory>[
        HomeCategory(
            id: 7,
            name: 'Home Cleaning',
            slug: 'home-cleaning',
            serviceCount: 12),
        HomeCategory(
            id: 8,
            name: 'Appliance Repair',
            slug: 'appliance-repair',
            serviceCount: 4),
      ],
      isStale: false,
    );

    for (final viewport in _viewports.entries) {
      for (final scale in _scales) {
        testWidgets('renders at ${viewport.key}, scale $scale', (tester) async {
          await render(
            tester,
            HomeMoreCategories(state: catalogOnly, onTap: (_) {}),
            viewport.value,
            scale,
          );

          expect(tester.takeException(), isNull);
          expect(find.text('More services'), findsOneWidget);
          expect(find.text('Home Cleaning'), findsOneWidget);
          expect(find.text('Appliance Repair'), findsOneWidget);
        });
      }
    }

    testWidgets('a curated category is not drawn twice', (tester) async {
      // Beauty & Wellness already has a hand-designed card above this row.
      // Drawing it again here is the failure the hyphen/underscore
      // normalisation exists to prevent.
      const withCurated = HomeCategoriesReady(
        <HomeCategory>[
          HomeCategory(
              id: 1, name: 'Beauty & Wellness', slug: 'beauty-wellness'),
          HomeCategory(id: 7, name: 'Home Cleaning', slug: 'home-cleaning'),
        ],
        isStale: false,
      );

      await render(
        tester,
        HomeMoreCategories(state: withCurated, onTap: (_) {}),
        const Size(390, 844),
        1.0,
      );

      expect(find.text('Beauty & Wellness'), findsNothing);
      expect(find.text('Home Cleaning'), findsOneWidget);
    });

    testWidgets('draws nothing when the catalog adds none', (tester) async {
      const onlyCurated = HomeCategoriesReady(
        <HomeCategory>[
          HomeCategory(id: 1, name: 'Massage', slug: 'massage'),
        ],
        isStale: false,
      );

      await render(
        tester,
        HomeMoreCategories(state: onlyCurated, onTap: (_) {}),
        const Size(390, 844),
        1.0,
      );

      expect(find.text('More services'), findsNothing);
    });

    testWidgets('draws nothing while loading or unavailable', (tester) async {
      for (final state in <HomeCategoriesState>[
        const HomeCategoriesLoading(),
        const HomeCategoriesUnavailable(null),
      ]) {
        await render(
          tester,
          HomeMoreCategories(state: state, onTap: (_) {}),
          const Size(390, 844),
          1.0,
        );
        expect(find.text('More services'), findsNothing);
      }
    });

    testWidgets('a tap reports the category, not its index', (tester) async {
      HomeCategory? tapped;
      await render(
        tester,
        HomeMoreCategories(state: catalogOnly, onTap: (c) => tapped = c),
        const Size(390, 844),
        1.0,
      );

      await tester.tap(find.text('Appliance Repair'));
      await tester.pump();

      // The id is what CatalogRoutes needs; a position would route to whatever
      // happened to be second that day.
      expect(tapped?.id, 8);
    });
  });

  group('Booking detail — Additional work', () {
    AdditionalWorkRequest req({
      int id = 1,
      AdditionalWorkStatus status = AdditionalWorkStatus.waitingForPayment,
      double? total = 750,
      double? approved,
      DateTime? paidAt,
    }) =>
        AdditionalWorkRequest(
          id: id,
          bookingId: '42',
          status: status,
          totalAmount: total,
          approvedAmount: approved,
          paidAt: paidAt,
        );

    for (final viewport in _viewports.entries) {
      for (final scale in _scales) {
        testWidgets('renders at ${viewport.key}, scale $scale', (tester) async {
          await render(
            tester,
            ChangeOrdersSection(
                state: ChangeOrdersReady(<AdditionalWorkRequest>[
              req(),
              req(id: 2, status: AdditionalWorkStatus.completed, approved: 500),
            ])),
            viewport.value,
            scale,
          );

          expect(tester.takeException(), isNull);
          expect(find.text('Additional work'), findsOneWidget);
          expect(find.text('Waiting for your payment'), findsOneWidget);
          expect(find.text('Completed'), findsOneWidget);
        });
      }
    }

    testWidgets('shows the agreed figure, not the asking price',
        (tester) async {
      // approvedAmount is what has been AGREED; totalAmount is what was ASKED
      // FOR. Rendering the request where the agreement belongs charges a
      // customer for a proposal.
      await render(
        tester,
        ChangeOrdersSection(
          state: ChangeOrdersReady(<AdditionalWorkRequest>[
            req(total: 900, approved: 500),
          ]),
        ),
        const Size(390, 844),
        1.0,
      );

      expect(find.textContaining('Agreed'), findsOneWidget);
      expect(find.textContaining('500'), findsOneWidget);
      expect(find.textContaining('900'), findsNothing);
    });

    testWidgets('labels an unagreed amount as requested', (tester) async {
      await render(
        tester,
        ChangeOrdersSection(
          state: ChangeOrdersReady(<AdditionalWorkRequest>[req(total: 900)]),
        ),
        const Size(390, 844),
        1.0,
      );

      expect(find.textContaining('Requested'), findsOneWidget);
    });

    testWidgets('counts only what waits on the customer', (tester) async {
      await render(
        tester,
        ChangeOrdersSection(
          state: ChangeOrdersReady(<AdditionalWorkRequest>[
            req(id: 1, status: AdditionalWorkStatus.waitingForPayment),
            req(id: 2, status: AdditionalWorkStatus.pendingAdminApproval),
            req(id: 3, status: AdditionalWorkStatus.waitingWorkerApproval),
          ]),
        ),
        const Size(390, 844),
        1.0,
      );

      // One of the three is the customer's to act on. A badge saying 3 would
      // ask them for two things they cannot give.
      expect(find.text('1 to pay'), findsOneWidget);
    });

    testWidgets('an unknown status is vague, never guessed', (tester) async {
      await render(
        tester,
        ChangeOrdersSection(
          state: ChangeOrdersReady(<AdditionalWorkRequest>[
            req(status: AdditionalWorkStatus.unknown),
          ]),
        ),
        const Size(390, 844),
        1.0,
      );

      // A build that meets a new server status must not present one the server
      // never claimed.
      expect(find.text('Additional work requested'), findsOneWidget);
    });

    testWidgets('draws nothing for a booking with no change orders',
        (tester) async {
      await render(
        tester,
        const ChangeOrdersSection(
          state: ChangeOrdersReady(<AdditionalWorkRequest>[]),
        ),
        const Size(390, 844),
        1.0,
      );

      // Almost every booking. An empty heading on all of them would be noise.
      expect(find.text('Additional work'), findsNothing);
    });

    testWidgets('draws nothing when they could not be read', (tester) async {
      await render(
        tester,
        const ChangeOrdersSection(state: ChangeOrdersUnavailable(null)),
        const Size(390, 844),
        1.0,
      );

      expect(find.text('Additional work'), findsNothing);
    });
  });
}
