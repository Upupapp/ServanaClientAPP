// ignore_for_file: avoid_print
/// Ground-truth integration probe (TAB 01).
///
/// Measures, on the day it is run, whether the backend the client is migrating
/// onto is actually there — and whether the legacy surface the SHIPPED app
/// depends on is still answering.
///
/// This exists because a recorded position was wrong. Memory held that
/// `/api/v1` was unreachable and `GET /api/catalog` returned 401; both were
/// false, and a migration was very nearly cancelled off a stale reading. The
/// probe turns that class of staleness into a red build.
///
///   dart run tool/integration_probe/integration_probe.dart \
///     --origin https://api.servana.com.ph
///
/// Read-only by construction. See [_isWrite] — a write path is probed with an
/// empty body, and 400/401 is the success signal. The probe must never create a
/// booking, a message, a dispute or a support ticket.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _defaultOrigin = 'https://api.servana.com.ph';
const _concurrency = 8;
const _timeout = Duration(seconds: 20);

/// Substituted for `:param` segments. Deliberately implausible: the probe wants
/// "is this route mounted", never "does this record exist".
const _paramStub = '999999999';

void main(List<String> argv) async {
  final args = _Args.parse(argv);
  final snapshot = jsonDecode(File(args.contractPath).readAsStringSync())
      as Map<String, dynamic>;

  final backendCommit = snapshot['backendCommit'] as String? ?? 'unknown';
  final backendDirty = snapshot['backendDirty'] as bool? ?? false;
  final v1 = (snapshot['v1'] as List).cast<Map<String, dynamic>>();
  final legacy = (snapshot['legacy'] as List).cast<Map<String, dynamic>>();

  final implemented = v1.where((e) => e['status'] == 'implemented').toList();
  final planned = v1.where((e) => e['status'] == 'planned').toList();

  stderr.writeln('probing ${args.origin}');
  stderr.writeln(
    '  contract: backend ${backendCommit.substring(0, 7)}'
    '${backendDirty ? '-dirty' : ''} — '
    '${implemented.length} implemented, ${planned.length} planned, '
    '${legacy.length} legacy mappings',
  );

  final startedAt = DateTime.now().toUtc();
  final client = HttpClient()..connectionTimeout = _timeout;

  final v1Results = await _mapLimited(
    implemented,
    (e) => _probeV1(client, args.origin, e),
  );
  final legacyResults = await _mapLimited(
    _groupLegacy(legacy),
    (e) => _probeLegacy(client, args.origin, e),
  );

  // A planned entry that ANSWERS is as much a contract defect as an
  // implemented one that 404s: the contract says it is not mounted.
  final plannedResults = await _mapLimited(
    planned,
    (e) => _probeV1(client, args.origin, e),
  );

  // Legacy routes the shipped app itself can construct. The contract's legacy
  // array and the client's call sites are DIFFERENT sets — production
  // deprecation-signposts routes the contract never declares — so probing only
  // one of them leaves a hole exactly where the field breakage would appear.
  final clientRoutes = _clientLegacyRoutes(args.apiClientPath ?? '');
  final clientRouteResults = await _mapLimited(
    clientRoutes,
    (r) => _probeClientRoute(client, args.origin, r),
  );

  client.close(force: true);
  final finishedAt = DateTime.now().toUtc();

  // ---- client endpoint constants -----------------------------------------
  // TAB 01 method (b): diff every path the client can construct against the
  // contract. Reported as SKIPPED rather than silently passing when the client
  // canonical layer is not present in the checkout — an unrun check that
  // reports green is the exact failure this TAB exists to prevent.
  final clientCheck = _checkClientEndpoints(args.clientEndpointsPath, v1);

  final findings = <String>[];

  // Unreachable is not the same claim as unmounted, and must never be dressed
  // up as one. A probe that cannot reach the origin knows NOTHING about the
  // contract, so it says so first and loudest rather than emitting a verdict
  // it has no evidence for.
  final unreachable = [
    ...v1Results,
    ...legacyResults,
    ...plannedResults,
    ...clientRouteResults
  ].where((r) => r.verdict == _Verdict.transportError).toList();
  if (unreachable.isNotEmpty) {
    findings.add(
      'TRANSPORT FAILURE: ${unreachable.length} request(s) to ${args.origin} did not '
      'complete (first: ${unreachable.first.error}). This run measured NOTHING '
      'about the contract — do not read any count below as evidence.',
    );
  }

  final notMounted =
      v1Results.where((r) => r.verdict == _Verdict.notMounted).toList();
  if (notMounted.isNotEmpty) {
    findings.add(
      'HARD FAILURE: ${notMounted.length} implemented contract path(s) are NOT MOUNTED on ${args.origin}. '
      'This is the exact condition that produced the false memory.',
    );
  }

  final legacyGone =
      legacyResults.where((r) => r.verdict == _Verdict.notMounted).toList();
  if (legacyGone.isNotEmpty) {
    findings.add(
      'P0: ${legacyGone.length} legacy path(s) the shipped app depends on have disappeared. '
      'Every installed build calling them is broken in the field right now.',
    );
  }

  final clientGone = clientRouteResults
      .where((r) => r.verdict == _Verdict.notMounted)
      .toList();
  if (clientGone.isNotEmpty) {
    findings.add(
      'P0: ${clientGone.length} route(s) the shipped client constructs no longer exist on '
      '${args.origin}. Every installed build calling them is broken in the field.',
    );
  }

  final contractLegacyKeys =
      _groupLegacy(legacy).map((e) => '${e['method']} ${e['path']}').toSet();
  final undeclared = clientRoutes
      .where((r) => !contractLegacyKeys.contains('${r['method']} ${r['path']}'))
      .toList();

  const mounted = {
    _Verdict.publicLive,
    _Verdict.gated,
    _Verdict.validating,
    _Verdict.rateLimited,
    _Verdict.mountedOther,
  };
  final plannedLive =
      plannedResults.where((r) => mounted.contains(r.verdict)).toList();
  if (plannedLive.isNotEmpty) {
    findings.add(
      'CONTRACT DRIFT: ${plannedLive.length} entr(ies) marked `planned` are answering. '
      'The contract says they are documented, not mounted.',
    );
  }

  final wrongSuccessor =
      legacyResults.where((r) => r.successorVerdict == 'WRONG').toList();
  if (wrongSuccessor.isNotEmpty) {
    findings.add(
      'SIGNPOST DEFECT: ${wrongSuccessor.length} legacy path(s) publish a '
      'Link rel="successor-version" that disagrees with the contract. '
      'RFC 8288 successor links are followed automatically by client generators.',
    );
  }

  if (clientCheck.skipped) {
    findings.add('SKIPPED: ${clientCheck.skipReason}');
  } else if (clientCheck.clientPathsNotInContract.isNotEmpty) {
    findings.add(
      'DIVERGENCE: ${clientCheck.clientPathsNotInContract.length} client path constant(s) '
      'are absent from the backend contract.',
    );
  }

  final baseline = <String, dynamic>{
    'probe': 'tool/integration_probe/integration_probe.dart',
    'origin': args.origin,
    'probedAtUtc': startedAt.toIso8601String(),
    'durationSeconds': finishedAt.difference(startedAt).inSeconds,
    'backendCommit': backendCommit,
    'backendDirty': backendDirty,
    'counts': {
      'v1Implemented': implemented.length,
      'v1Planned': planned.length,
      'legacyProbed': legacyResults.length,
      'v1NotMounted': notMounted.length,
      'legacyNotMounted': legacyGone.length,
      'plannedAnswering': plannedLive.length,
      'wrongSuccessor': wrongSuccessor.length,
      'clientRoutesProbed': clientRoutes.length,
      'clientRoutesNotMounted': clientGone.length,
      'clientRoutesUndeclaredByContract': undeclared.length,
    },
    'clientRoutesProbed': clientRoutes.length,
    'clientRoutesUndeclaredByContract':
        undeclared.map((r) => '${r['method']} ${r['path']}').toList(),
    'clientRouteResults': clientRouteResults.map((r) => r.toJson()).toList(),
    'v1ByVerdict': _tally(v1Results),
    'legacyByVerdict': _tally(legacyResults),
    'clientEndpointCheck': clientCheck.toJson(),
    'findings': findings,
    'v1': v1Results.map((r) => r.toJson()).toList(),
    'legacy': legacyResults.map((r) => r.toJson()).toList(),
    'planned': plannedResults.map((r) => r.toJson()).toList(),
  };

  Directory(args.outDir).createSync(recursive: true);
  File('${args.outDir}/baseline.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(baseline)}\n');
  File('${args.outDir}/BASELINE.md').writeAsStringSync(
    _renderMarkdown(
        baseline, v1Results, legacyResults, plannedResults, clientCheck),
  );

  stderr.writeln('');
  stderr.writeln('v1 (implemented):  ${_tally(v1Results)}');
  stderr.writeln('legacy (contract): ${_tally(legacyResults)}');
  stderr.writeln('legacy (client):   ${_tally(clientRouteResults)}'
      '  [${clientRoutes.length} call sites, '
      '${undeclared.length} undeclared by contract]');
  stderr.writeln('wrote ${args.outDir}/BASELINE.md and baseline.json');

  final hardFail = unreachable.isNotEmpty ||
      notMounted.isNotEmpty ||
      legacyGone.isNotEmpty ||
      clientGone.isNotEmpty ||
      plannedLive.isNotEmpty ||
      (!clientCheck.skipped && clientCheck.clientPathsNotInContract.isNotEmpty);

  if (findings.isNotEmpty) {
    stderr.writeln('');
    for (final f in findings) {
      stderr.writeln('  ! $f');
    }
  }

  if (hardFail) {
    stderr.writeln('\nPROBE FAILED');
    exit(1);
  }
  // The successor defect is a real backend bug (TAB 03) but it does not mean
  // the client cannot migrate, so it is advisory unless --strict.
  if (wrongSuccessor.isNotEmpty && args.strict) {
    stderr.writeln('\nPROBE FAILED (--strict: successor signpost)');
    exit(1);
  }
  stderr.writeln('\nPROBE PASSED');
}

// ---------------------------------------------------------------------------

enum _Verdict {
  publicLive, // 200 — mounted, public
  gated, // 401/403 — mounted, auth enforced
  validating, // 400/409/422 — mounted, input validated
  rateLimited, // 429 — mounted, and the limiter is doing its job
  mountedOther, // any other status from a mounted route
  notMounted, // router-level 404: the route does not exist
  transportError,
}

class _Result {
  _Result({
    required this.id,
    required this.method,
    required this.path,
    required this.expectedAuth,
    required this.status,
    required this.verdict,
    this.disposition,
    this.deprecation,
    this.sunset,
    this.link,
    this.expectedSuccessor,
    this.successorVerdict,
    this.error,
  });

  final String id;
  final String method;
  final String path;
  final String? expectedAuth;
  final int status;
  final _Verdict verdict;
  final String? disposition;
  final String? deprecation;
  final String? sunset;
  final String? link;
  final String? expectedSuccessor;
  final String? successorVerdict;
  final String? error;

  Map<String, dynamic> toJson() => {
        'id': id,
        'method': method,
        'path': path,
        if (expectedAuth != null) 'contractAuth': expectedAuth,
        'status': status,
        'verdict': verdict.name,
        if (disposition != null) 'disposition': disposition,
        if (deprecation != null) 'deprecation': deprecation,
        if (sunset != null) 'sunset': sunset,
        if (link != null) 'link': link,
        if (expectedSuccessor != null) 'contractSuccessor': expectedSuccessor,
        if (successorVerdict != null) 'successorVerdict': successorVerdict,
        if (error != null) 'error': error,
      };
}

bool _isWrite(String method) =>
    method == 'POST' ||
    method == 'PUT' ||
    method == 'PATCH' ||
    method == 'DELETE';

String _concrete(String path) =>
    path.replaceAllMapped(RegExp(r':([A-Za-z0-9_]+)'), (_) => _paramStub);

/// A 404 is ambiguous: the router may not have the route, or the handler may
/// not have the record. The v1 router answers an unmounted path with a
/// distinctive envelope, so the two are separable rather than guessed at.
bool _isRouterMiss(String body, String path) {
  if (body.isEmpty) return true;
  final lower = body.toLowerCase();
  if (lower.contains('no v1 endpoint for')) return true;
  if (lower.contains('cannot get') || lower.contains('cannot post')) {
    return true;
  }
  // A JSON error naming NOT_FOUND *without* the router phrasing is a handler
  // saying the record is missing — which means the route IS mounted.
  return false;
}

Future<_Result> _probeV1(
  HttpClient client,
  String origin,
  Map<String, dynamic> e,
) async {
  final method = e['method'] as String;
  final path = e['path'] as String;
  final res = await _send(client, origin, method, _concrete(path));

  if (res.transportError != null) {
    return _Result(
      id: e['id'] as String,
      method: method,
      path: path,
      expectedAuth: e['auth'] as String?,
      status: -1,
      verdict: _Verdict.transportError,
      error: res.transportError,
    );
  }

  return _Result(
    id: e['id'] as String,
    method: method,
    path: path,
    expectedAuth: e['auth'] as String?,
    status: res.status,
    verdict: _classify(res, path),
  );
}

Future<_Result> _probeLegacy(
  HttpClient client,
  String origin,
  Map<String, dynamic> e,
) async {
  final method = e['method'] as String;
  final path = e['path'] as String;
  final res = await _send(client, origin, method, _concrete(path));

  if (res.transportError != null) {
    return _Result(
      id: (e['supersededBy'] as List).join(','),
      method: method,
      path: path,
      expectedAuth: null,
      status: -1,
      verdict: _Verdict.transportError,
      disposition: (e['dispositions'] as List).join(','),
      error: res.transportError,
    );
  }

  // The deprecation clock, as production is publishing it today.
  final link = res.headers['link'];
  final successors = (e['successors'] as List).cast<String>();
  final dispositions = (e['dispositions'] as List).cast<String>();
  final expected = successors.join(' | ');
  String? successorVerdict;
  if (link != null && successors.isNotEmpty) {
    final emitted = RegExp(r'<([^>]+)>').firstMatch(link)?.group(1);
    if (emitted != null) {
      successorVerdict = successors.contains(emitted) ? 'OK' : 'WRONG';
    }
  } else if (link == null && dispositions.contains('ALIAS_TEMPORARILY')) {
    successorVerdict = 'MISSING';
  }

  return _Result(
    id: (e['supersededBy'] as List).join(','),
    method: method,
    path: path,
    expectedAuth: null,
    status: res.status,
    verdict: _classify(res, path),
    disposition: dispositions.toSet().join(','),
    deprecation: res.headers['deprecation'],
    sunset: res.headers['sunset'],
    link: link,
    expectedSuccessor: expected,
    successorVerdict: successorVerdict,
  );
}

Future<_Result> _probeClientRoute(
  HttpClient client,
  String origin,
  Map<String, String> r,
) async {
  final method = r['method']!;
  final path = r['path']!;
  final res = await _send(client, origin, method, path);
  if (res.transportError != null) {
    return _Result(
      id: 'client-call-site',
      method: method,
      path: path,
      expectedAuth: null,
      status: -1,
      verdict: _Verdict.transportError,
      error: res.transportError,
    );
  }
  return _Result(
    id: 'client-call-site',
    method: method,
    path: path,
    expectedAuth: null,
    status: res.status,
    verdict: _classify(res, path),
    deprecation: res.headers['deprecation'],
    sunset: res.headers['sunset'],
    link: res.headers['link'],
  );
}

_Verdict _classify(_Res res, String path) {
  switch (res.status) {
    case 200:
    case 201:
    case 204:
      return _Verdict.publicLive;
    case 401:
    case 403:
      return _Verdict.gated;
    case 400:
    case 409:
    case 422:
      return _Verdict.validating;
    // A 429 is positive evidence of mounting: the limiter sits in front of a
    // route that exists. Probing the auth surface repeatedly trips it by
    // design, so it gets its own verdict rather than drifting between buckets
    // run to run and reading as instability.
    case 429:
      return _Verdict.rateLimited;
    case 404:
      return _isRouterMiss(res.body, path)
          ? _Verdict.notMounted
          : _Verdict.mountedOther;
    default:
      return _Verdict.mountedOther;
  }
}

class _Res {
  _Res(this.status, this.body, this.headers, {this.transportError});
  final int status;
  final String body;
  final Map<String, String> headers;
  final String? transportError;
}

Future<_Res> _send(
  HttpClient client,
  String origin,
  String method,
  String path,
) async {
  try {
    final req = await client
        .openUrl(method, Uri.parse('$origin$path'))
        .timeout(_timeout);
    req.followRedirects = false;
    req.headers.set('accept', 'application/json');
    req.headers.set('user-agent', 'servana-client-integration-probe/1');
    if (_isWrite(method)) {
      // Empty object, never a payload that could create anything.
      final body = utf8.encode('{}');
      req.headers.set('content-type', 'application/json');
      req.headers.set('x-probe-read-only', 'true');
      req.contentLength = body.length;
      req.add(body);
    }
    final resp = await req.close().timeout(_timeout);
    final body = await utf8.decoder
        .bind(resp)
        .join()
        .timeout(_timeout)
        .catchError((_) => '');
    final headers = <String, String>{};
    resp.headers.forEach((k, v) => headers[k.toLowerCase()] = v.join(', '));
    return _Res(resp.statusCode, body, headers);
  } on Object catch (err) {
    return _Res(-1, '', const {}, transportError: err.toString());
  }
}

/// One legacy route may be declared by SEVERAL v1 entries — `/api/user/profile`
/// is claimed by both `identity.me` (ROLE_SPECIFIC) and `customer.profile.get`
/// (ALIAS_TEMPORARILY). Keeping only the first seen and comparing against it
/// reports a correct signpost as WRONG, so every declared successor is carried
/// and a published link matching ANY of them is correct.
List<Map<String, dynamic>> _groupLegacy(List<Map<String, dynamic>> legacy) {
  final byRoute = <String, Map<String, dynamic>>{};
  for (final e in legacy) {
    final key = '${e['method']} ${e['path']}';
    final g = byRoute.putIfAbsent(
      key,
      () => <String, dynamic>{
        'method': e['method'],
        'path': e['path'],
        'successors': <String>[],
        'dispositions': <String>[],
        'supersededBy': <String>[],
      },
    );
    (g['successors'] as List<String>).add(e['expectedSuccessor'] as String);
    (g['dispositions'] as List<String>).add(e['disposition'] as String);
    (g['supersededBy'] as List<String>).add(e['supersededBy'] as String);
  }
  return byRoute.values.toList();
}

Future<List<R>> _mapLimited<T, R>(
  List<T> items,
  Future<R> Function(T) fn,
) async {
  final out = List<R?>.filled(items.length, null);
  var next = 0;
  Future<void> worker() async {
    while (true) {
      final i = next++;
      if (i >= items.length) return;
      out[i] = await fn(items[i]);
    }
  }

  await Future.wait(
    List.generate(_concurrency < items.length ? _concurrency : items.length,
        (_) => worker()),
  );
  return out.cast<R>();
}

Map<String, int> _tally(List<_Result> rs) {
  final m = <String, int>{};
  for (final r in rs) {
    m[r.verdict.name] = (m[r.verdict.name] ?? 0) + 1;
  }
  return m;
}

// ---------------------------------------------------------------------------

/// Every legacy route the SHIPPED app can construct, read out of the client
/// source rather than listed by hand — so a call added tomorrow cannot escape
/// the probe by nobody remembering to add it here.
///
/// The client builds every request as `_uri('/api/...')` followed within a few
/// lines by `_client.<verb>(uri, ...)`, so path and method are paired by
/// scanning forward from each `_uri` to the verb that consumes it. Pairing
/// matters: probing a POST-only route with GET draws a router 404 and would
/// report a live route as a P0 outage.
List<Map<String, String>> _clientLegacyRoutes(String path) {
  final f = File(path);
  if (!f.existsSync()) return const [];
  final lines = f.readAsLinesSync();
  final uriRe = RegExp(r"_uri\(\s*'(/api[^']*)'");
  final verbRe = RegExp(r'_client\.(get|post|put|patch|delete)\b');
  final out = <String, Map<String, String>>{};

  for (var i = 0; i < lines.length; i++) {
    final m = uriRe.firstMatch(lines[i]);
    if (m == null) continue;
    var raw = m.group(1)!;
    // '/api/services/$serviceId/level2' -> concrete, probe-safe path.
    raw = raw
        .replaceAll(RegExp(r'\$\{[^}]*\}'), _paramStub)
        .replaceAll(RegExp(r'\$[A-Za-z_][A-Za-z0-9_]*'), _paramStub);
    String verb = 'GET';
    for (var j = i; j < lines.length && j < i + 20; j++) {
      final v = verbRe.firstMatch(lines[j]);
      if (v != null) {
        verb = v.group(1)!.toUpperCase();
        break;
      }
    }
    out['$verb $raw'] = {'method': verb, 'path': raw};
  }
  final list = out.values.toList()
    ..sort((a, b) => ('${a['method']} ${a['path']}')
        .compareTo('${b['method']} ${b['path']}'));
  return list;
}

class _ClientCheck {
  _ClientCheck.skippedBecause(this.skipReason)
      : skipped = true,
        clientPaths = const [],
        clientPathsNotInContract = const [],
        contractPathsClientNeverNames = const [];

  _ClientCheck.ran({
    required this.clientPaths,
    required this.clientPathsNotInContract,
    required this.contractPathsClientNeverNames,
  })  : skipped = false,
        skipReason = null;

  final bool skipped;
  final String? skipReason;
  final List<String> clientPaths;
  final List<String> clientPathsNotInContract;
  final List<String> contractPathsClientNeverNames;

  Map<String, dynamic> toJson() => {
        'skipped': skipped,
        if (skipReason != null) 'skipReason': skipReason,
        'clientPathCount': clientPaths.length,
        'clientPathsNotInContract': clientPathsNotInContract,
        'contractPathsClientNeverNames': contractPathsClientNeverNames,
      };
}

_ClientCheck _checkClientEndpoints(
    String? path, List<Map<String, dynamic>> v1) {
  if (path == null) {
    return _ClientCheck.skippedBecause(
      'no --client-endpoints given; the client v1 path constants were not diffed '
      'against the contract',
    );
  }
  final f = File(path);
  if (!f.existsSync()) {
    return _ClientCheck.skippedBecause(
      'client endpoint constants not found at $path — the canonical v1 client '
      'layer is absent from this checkout, so client/contract divergence was '
      'NOT measured',
    );
  }
  final src = f.readAsStringSync();
  final paths = RegExp(r"'(/[A-Za-z0-9_\-/:{}\.]*)'")
      .allMatches(src)
      .map((m) => m.group(1)!)
      .where((p) => p.length > 1)
      .toSet()
      .toList()
    ..sort();

  final contractPaths =
      v1.map((e) => (e['path'] as String).replaceFirst('/api/v1', '')).toSet();
  final implementedPaths = v1
      .where((e) => e['status'] == 'implemented')
      .map((e) => (e['path'] as String).replaceFirst('/api/v1', ''))
      .toSet();

  return _ClientCheck.ran(
    clientPaths: paths,
    clientPathsNotInContract:
        paths.where((p) => !contractPaths.contains(p)).toList(),
    contractPathsClientNeverNames:
        implementedPaths.where((p) => !paths.contains(p)).toList()..sort(),
  );
}

// ---------------------------------------------------------------------------

class _Args {
  _Args({
    required this.origin,
    required this.contractPath,
    required this.outDir,
    required this.clientEndpointsPath,
    required this.apiClientPath,
    required this.strict,
  });

  final String origin;
  final String contractPath;
  final String outDir;
  final String? clientEndpointsPath;
  final String? apiClientPath;
  final bool strict;

  static _Args parse(List<String> argv) {
    String origin = _defaultOrigin;
    String contract = 'docs/integration/contract_snapshot.json';
    String outDir = 'docs/integration';
    String? clientEndpoints;
    String? apiClient = 'lib/common/data/backend/servana_api_client.dart';
    bool strict = false;
    for (var i = 0; i < argv.length; i++) {
      switch (argv[i]) {
        case '--origin':
          origin = argv[++i];
        case '--contract':
          contract = argv[++i];
        case '--out-dir':
          outDir = argv[++i];
        case '--client-endpoints':
          clientEndpoints = argv[++i];
        case '--api-client':
          apiClient = argv[++i];
        case '--strict':
          strict = true;
        case '-h':
        case '--help':
          print('usage: dart run tool/integration_probe/integration_probe.dart '
              '[--origin URL] [--contract FILE] [--out-dir DIR] '
              '[--client-endpoints FILE] [--strict]');
          exit(0);
      }
    }
    return _Args(
      origin: origin.replaceAll(RegExp(r'/$'), ''),
      contractPath: contract,
      outDir: outDir,
      clientEndpointsPath: clientEndpoints,
      apiClientPath: apiClient,
      strict: strict,
    );
  }
}

String _renderMarkdown(
  Map<String, dynamic> b,
  List<_Result> v1,
  List<_Result> legacy,
  List<_Result> planned,
  _ClientCheck client,
) {
  final sb = StringBuffer();
  final counts = b['counts'] as Map<String, dynamic>;
  sb.writeln('# Integration baseline');
  sb.writeln();
  sb.writeln('> Generated by `tool/integration_probe/integration_probe.dart`. '
      'Do not edit by hand — re-run the probe.');
  sb.writeln();
  sb.writeln('| | |');
  sb.writeln('| --- | --- |');
  sb.writeln('| Origin probed | `${b['origin']}` |');
  sb.writeln('| Probed at (UTC) | ${b['probedAtUtc']} |');
  sb.writeln('| Duration | ${b['durationSeconds']}s |');
  sb.writeln('| Backend contract commit | `${b['backendCommit']}`'
      '${b['backendDirty'] == true ? ' **(working tree dirty)**' : ''} |');
  sb.writeln('| Implemented v1 entries | ${counts['v1Implemented']} |');
  sb.writeln('| Planned v1 entries | ${counts['v1Planned']} |');
  sb.writeln('| Legacy routes probed | ${counts['legacyProbed']} |');
  sb.writeln();

  sb.writeln('## Verdict');
  sb.writeln();
  final findings = (b['findings'] as List).cast<String>();
  if (findings.isEmpty) {
    sb.writeln('No divergence. Every implemented contract path is mounted, '
        'every legacy path the shipped app depends on still answers, and the '
        'published successor links agree with the contract.');
  } else {
    for (final f in findings) {
      sb.writeln('- $f');
    }
  }
  sb.writeln();

  sb.writeln('## v1 — implemented (${v1.length})');
  sb.writeln();
  sb.writeln('Classification: `publicLive` 200 · `gated` 401/403 · '
      '`validating` 400/409/422 · `rateLimited` 429 · `mountedOther` a handler '
      "404 or other status from a route that exists · `notMounted` a *router*"
      ' 404 (**hard failure**).');
  sb.writeln();
  sb.writeln('Every verdict except `notMounted` and `transportError` is '
      'evidence the route is mounted.');
  sb.writeln();
  sb.writeln('${b['v1ByVerdict']}');
  sb.writeln();
  sb.writeln('| Method | Path | Contract auth | Status | Verdict |');
  sb.writeln('| --- | --- | --- | --- | --- |');
  for (final r in v1..sort((a, c) => a.path.compareTo(c.path))) {
    sb.writeln(
        '| ${r.method} | `${r.path}` | ${r.expectedAuth} | ${r.status} | '
        '${r.verdict == _Verdict.notMounted ? '**${r.verdict.name}**' : r.verdict.name} |');
  }
  sb.writeln();

  if (planned.isNotEmpty) {
    sb.writeln('## v1 — planned (${planned.length})');
    sb.writeln();
    sb.writeln('The contract documents these and does NOT mount them. '
        'A planned entry that answers is contract drift.');
    sb.writeln();
    sb.writeln('| Method | Path | Status | Verdict |');
    sb.writeln('| --- | --- | --- | --- |');
    for (final r in planned) {
      sb.writeln(
          '| ${r.method} | `${r.path}` | ${r.status} | ${r.verdict.name} |');
    }
    sb.writeln();
  }

  sb.writeln('## Legacy — the deprecation clock (${legacy.length})');
  sb.writeln();
  sb.writeln(
      '`successor` compares the `Link rel="successor-version"` production '
      'publishes against the successor the contract declares. `WRONG` means the '
      'backend is signposting migrating clients at the wrong endpoint.');
  sb.writeln();
  sb.writeln('${b['legacyByVerdict']}');
  sb.writeln();
  sb.writeln('| Method | Path | Disposition | Status | Verdict | Deprecation | '
      'Successor published | Contract successor | successor |');
  sb.writeln('| --- | --- | --- | --- | --- | --- | --- | --- | --- |');
  for (final r in legacy..sort((a, c) => a.path.compareTo(c.path))) {
    final emitted = r.link == null
        ? '—'
        : RegExp(r'<([^>]+)>').firstMatch(r.link!)?.group(1) ?? r.link!;
    sb.writeln(
        '| ${r.method} | `${r.path}` | ${r.disposition ?? '—'} | ${r.status} | '
        '${r.verdict == _Verdict.notMounted ? '**${r.verdict.name}**' : r.verdict.name} | '
        '${r.deprecation ?? '—'} | `$emitted` | `${r.expectedSuccessor ?? '—'}` | '
        '${r.successorVerdict == 'WRONG' ? '**WRONG**' : r.successorVerdict ?? '—'} |');
  }
  sb.writeln();

  sb.writeln('## Legacy routes the shipped client constructs');
  sb.writeln();
  sb.writeln(
      'Enumerated from the client source, not from a list. These are the '
      'routes an installed build actually calls today; a 404 here is a live '
      'field outage, not a migration concern.');
  sb.writeln();
  final crs = (b['clientRouteResults'] as List).cast<Map<String, dynamic>>();
  final undecl =
      (b['clientRoutesUndeclaredByContract'] as List).cast<String>().toSet();
  sb.writeln('- Call sites probed: ${crs.length}');
  sb.writeln('- Not mounted (**P0**): '
      '${crs.where((r) => r['verdict'] == 'notMounted').length}');
  sb.writeln('- Not declared as legacy by the contract: ${undecl.length}');
  sb.writeln();
  sb.writeln(
      '| Method | Path | Status | Verdict | Deprecation | In contract |');
  sb.writeln('| --- | --- | --- | --- | --- | --- |');
  for (final r in crs) {
    final key = '${r['method']} ${r['path']}';
    sb.writeln('| ${r['method']} | `${r['path']}` | ${r['status']} | '
        '${r['verdict'] == 'notMounted' ? '**notMounted**' : r['verdict']} | '
        '${r['deprecation'] ?? '—'} | ${undecl.contains(key) ? '**no**' : 'yes'} |');
  }
  sb.writeln();

  sb.writeln('## Client path constants vs contract');
  sb.writeln();
  if (client.skipped) {
    sb.writeln('**SKIPPED — ${client.skipReason}**');
    sb.writeln();
    sb.writeln('This check is one half of TAB 01 and it did not run. Nothing '
        'below should be read as evidence that the client and the contract agree.');
  } else {
    sb.writeln('- Client path constants found: ${client.clientPaths.length}');
    sb.writeln(
        '- Absent from the contract: ${client.clientPathsNotInContract.length}');
    sb.writeln('- Implemented contract paths the client never names: '
        '${client.contractPathsClientNeverNames.length}');
    if (client.clientPathsNotInContract.isNotEmpty) {
      sb.writeln();
      for (final p in client.clientPathsNotInContract) {
        sb.writeln('  - `$p` **not in contract**');
      }
    }
    if (client.contractPathsClientNeverNames.isNotEmpty) {
      sb.writeln();
      sb.writeln('Live endpoints nobody is calling:');
      for (final p in client.contractPathsClientNeverNames) {
        sb.writeln('  - `$p`');
      }
    }
  }
  sb.writeln();
  return sb.toString();
}
