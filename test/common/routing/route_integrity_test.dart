import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every named navigation target must be a route the router declares.
///
/// ## What this catches
///
/// `context.goNamed('X')` on a name GoRouter does not know throws
/// `GoException: no routes for name` — at runtime, on tap, with no compile-time
/// warning and no test failure. It is invisible until a customer finds it.
///
/// The `job_order` module shipped exactly that: a checkout screen whose
/// "Continue" button called `goNamed` on two names the router never declared,
/// for both the cash and the QR branch. It was unreachable, so nobody hit it —
/// but wiring that screen into the router would have crashed the money path on
/// first tap.
///
/// ## Why it reads the source rather than the router object
///
/// Building the real `GoRouter` needs the dependency graph, Firebase and a
/// binding. This asks a narrower question that needs none of them: does every
/// name passed to a `*Named` call appear as a `name:` in the route table? A
/// test that needs the whole app to start is a test that gets skipped.
void main() {
  final libDir = Directory('lib');
  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  /// `static const routeName = 'X'` / `static String routeName = "X"`, attributed
  /// to the class it sits in.
  final constValue = <String, String>{};
  for (final f in dartFiles) {
    final src = f.readAsStringSync();
    final classes = RegExp(r'class\s+(\w+)\s').allMatches(src).toList();
    for (final m in RegExp(
      r'''static\s+(?:const|final)?\s*(?:String\s+)?routeName\s*=\s*['"]([^'"]+)['"]''',
    ).allMatches(src)) {
      final before = classes.where((c) => c.start < m.start);
      if (before.isNotEmpty) {
        constValue['${before.last.group(1)}.routeName'] = m.group(1)!;
      }
    }
  }

  final routerSrc = File('lib/common/presentation/routes/main_router.dart')
      .readAsStringSync();

  String resolve(String expr) => expr.startsWith("'") || expr.startsWith('"')
      ? expr.substring(1, expr.length - 1)
      : constValue[expr] ?? expr;

  final declared = RegExp(
    r'''name:\s*([A-Za-z_][\w.]*\.routeName|'[^']+'|"[^"]+")''',
  ).allMatches(routerSrc).map((m) => resolve(m.group(1)!)).toSet();

  test('the router declares a meaningful number of routes', () {
    // Guards the vacuous pass: a broken parser declares nothing and makes every
    // navigation below trivially "undeclared", or nothing at all.
    expect(declared.length, greaterThan(40));
    expect(constValue.length, greaterThan(40));
  });

  test('every named navigation target is a declared route', () {
    final offenders = <String>[];
    final pattern = RegExp(
      r'''\b(?:push|go|pushReplacement|replace)Named\s*\(\s*([A-Za-z_][\w.]*\.routeName|'[^']+'|"[^"]+")''',
    );

    for (final f in dartFiles) {
      if (f.path.endsWith('main_router.dart')) continue;
      final src = f.readAsStringSync();
      for (final m in pattern.allMatches(src)) {
        final name = resolve(m.group(1)!);
        if (!declared.contains(name)) {
          offenders.add('${f.path}  ->  $name');
        }
      }
    }

    // The message carries the file and the name: "expected 0, got 2" is the
    // start of a search rather than the end of one.
    expect({'count': offenders.length, 'offenders': offenders},
        {'count': 0, 'offenders': <String>[]});
  });
}
