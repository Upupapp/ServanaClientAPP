/// Terminal screen for a catalog link that cannot resolve to a canonical id.
///
/// Reached when a deep link carries a malformed or non-numeric id — a legacy
/// link built before the migration, a truncated share, or a hand-typed URL.
///
/// It deliberately does NOT redirect anywhere. §54 is explicit that an
/// unresolvable Service link must land on an honest "unavailable", never be
/// silently rerouted to some other Service the customer did not ask for.
library;

import 'package:flutter/material.dart';

import 'package:client/modules/catalog/presentation/widgets/catalog_widgets.dart';

class CatalogUnavailableScreen extends StatelessWidget {
  const CatalogUnavailableScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Service')),
        body: const SafeArea(
          child: CatalogEmptyView(
            message: 'This service is currently unavailable.',
          ),
        ),
      );
}
