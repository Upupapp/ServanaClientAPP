/// Home composition over the canonical `/api/v1/home` namespace.
///
/// ## Not reachable in any shipped build
///
/// Selected only when `CanonicalAvailability.isAvailable(V1Capability.home)` is
/// true, which requires `--dart-define=CANONICAL_V1_ENABLED=true` AND `home` in
/// `CANONICAL_V1_CAPABILITIES`. No production build passes either: `/api/v1` is
/// absent from the backend's `origin/main`.
///
/// ## One fetch, not seven
///
/// This is the performance half of the tab. The compatibility source makes
/// several calls and assembles them; this makes one and lets the backend
/// compose, which is the whole reason a composition endpoint exists. Nothing
/// here re-derives Service or Booking truth — it renders what the composition
/// returned.
library;

import 'package:client/core/network/api_error_mapper.dart';
import 'package:client/core/network/api_failure.dart';
import 'package:client/core/network/v1_api_client.dart';
import 'package:client/core/network/v1_endpoints.dart';
import 'package:client/modules/homepage/data/home_composition_data_source.dart';
import 'package:client/modules/homepage/domain/home_composition.dart';

class HomeCompositionCanonicalDataSource implements HomeCompositionDataSource {
  HomeCompositionCanonicalDataSource(
    this._api, {
    ApiErrorMapper mapper = const ApiErrorMapper(),
  }) : _mapper = mapper;

  final V1ApiClient _api;
  final ApiErrorMapper _mapper;

  @override
  Future<HomeComposition> fetchComposition() async {
    // A failure here IS total — the one request that could have produced Home
    // did not. Rethrown rather than swallowed so the caller can serve cache.
    final envelope = await _api.get(V1Endpoints.home());
    final data = envelope.asMap;
    if (data.isEmpty) {
      throw const FormatException('Home composition response had no data');
    }
    return HomeComposition.fromJson(data);
  }

  /// Re-fetches one section.
  ///
  /// This narrows the composition endpoint with `?sections=<name>` — it does
  /// **not** call `/api/v1/home/sections`. That route is the section *registry*
  /// (`homeService.describeSections`: type, audience, failureMode, ownedBy,
  /// ttlSeconds); it is metadata, it names no resource, and it accepts no
  /// section parameter. Asking it for content would be inventing a server
  /// behaviour that does not exist.
  @override
  Future<HomeSection> fetchSection(HomeSectionType type) async {
    try {
      final envelope = await _api.get(
        V1Endpoints.home(),
        query: <String, dynamic>{'sections': type.requestName},
      );
      final composition = HomeComposition.fromJson(envelope.asMap);
      final section = composition.sections[type];
      // A section the backend declined to return is absent, not failed: it may
      // simply not apply to this customer, and a retry button for something
      // that does not exist is noise.
      return section ?? HomeSectionAbsent(type);
    } catch (error) {
      return HomeSectionFailed(type, _asFailure(error));
    }
  }

  ApiFailure _asFailure(Object error) => error is ApiFailure
      ? error
      : _mapper.fromTransport(error);
}
