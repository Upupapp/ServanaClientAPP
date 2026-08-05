/// No single bundled asset may be large enough to move the download size.
///
/// Play flagged 1.0.0+37 with "This artifact significantly increases the size of
/// APK(s) downloaded by users. Larger apps see lower install and update success
/// rates." The four category campaign creatives were the cause: 941×1672
/// photographic posters saved as PNG, 1.8–1.95 MB each, and PNG barely
/// compresses photographic content — 1.95 MB became 1.93 MB in the bundle.
/// Together with the three welcome backgrounds that was 11.5 MB of a 33 MB
/// download.
///
/// The same artwork as WebP is 1.58 MB — 86% smaller, at 35–37 dB PSNR in the
/// CTA regions measured at real display size, and 44–46 dB on the backgrounds.
///
/// It reached production because nothing measured it. The launch banner already
/// shipped as a 0.28 MB WebP right beside the popups, so the convention existed
/// and simply was not applied.
///
/// This asserts on the DECLARED asset tree — the files pubspec actually bundles
/// — rather than on everything under assets/. `assets/images/services/
/// service_icon/` holds six 1.8 MB PNGs that ship to nobody, because Flutter
/// does not recurse into undeclared subdirectories. Failing on those would be
/// noise, and noise is what gets a guard ignored.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// Above this, a single MEDIA asset is worth a conversation.
///
/// The ceiling applies to media only, and that distinction is the point. The
/// first version of this test measured every bundled file on disk and failed on
/// `barangay.json` at 4,673 KB — which ships at roughly 370 KB, because JSON
/// compresses about 10:1 inside the bundle. On-disk size is a fair proxy for
/// what an image costs a customer and a badly misleading one for text.
const int _maxMediaBytes = 600 * 1024;

/// Formats already compressed, where the file on disk is close to the bytes
/// downloaded.
const Set<String> _mediaExtensions = {
  '.png',
  '.jpg',
  '.jpeg',
  '.webp',
  '.gif',
  '.bmp',
  '.tiff',
  '.mp4',
  '.mov',
  '.webm',
  '.ttf',
  '.otf',
  '.woff',
  '.woff2',
};

/// Photographic formats that compress badly and have a better alternative.
const Set<String> _wastefulForPhotos = {'.png', '.bmp', '.tiff'};

String? _ext(File f) {
  // A file with no dot at all is legitimate in the asset tree, and
  // lastIndexOf returning -1 threw when this used substring directly.
  final dot = f.path.lastIndexOf('.');
  if (dot < 0) return null;
  return f.path.toLowerCase().substring(dot);
}

List<Directory> _declaredAssetDirs() {
  final doc = loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
  final assets = (doc['flutter'] as YamlMap)['assets'] as YamlList;
  return assets
      .map((e) => e.toString())
      .where((e) => e.endsWith('/'))
      .map(Directory.new)
      .where((d) => d.existsSync())
      .toList();
}

/// Files Flutter actually bundles: the declared directory, NOT its subtrees.
List<File> _bundledFiles() {
  final out = <File>[];
  for (final dir in _declaredAssetDirs()) {
    for (final e in dir.listSync(followLinks: false)) {
      if (e is File) out.add(e);
    }
  }
  return out;
}

void main() {
  group('bundled assets stay small', () {
    test('the declared asset tree is non-empty', () {
      // If this ever reads zero the guard below passes while checking nothing —
      // most likely because the pubspec shape changed, not because the assets
      // vanished.
      expect(_bundledFiles(), isNotEmpty);
      expect(_declaredAssetDirs().length, greaterThan(5));
    });

    test('no bundled media file exceeds the size ceiling', () {
      final offenders = <String>[];
      for (final f in _bundledFiles()) {
        final ext = _ext(f);
        if (ext == null || !_mediaExtensions.contains(ext)) continue;
        if (f.lengthSync() > _maxMediaBytes) {
          offenders.add('${f.path.replaceAll(r'\', '/')}  '
              '${(f.lengthSync() / 1024).toStringAsFixed(0)} KB');
        }
      }
      expect(offenders, isEmpty,
          reason: 'these ship to every customer on every install and update.\n'
              'Convert photographic artwork to WebP — it was 86% smaller here '
              'with no visible loss:\n${offenders.join('\n')}');
    });

    test('no large photographic asset is still a PNG', () {
      // Narrower than the ceiling above and aimed at the actual mistake: a
      // poster or photo saved in a format that cannot compress it. Small PNGs
      // — icons, flat colour, line art — are exactly right and are left alone.
      //
      // A logo with hard edges is the awkward case: lossy WebP can ring on it.
      // Default.webp is stored LOSSLESS for that reason — still 38% smaller
      // than the PNG, with no pixel changed.
      final offenders = <String>[];
      for (final f in _bundledFiles()) {
        final ext = _ext(f);
        if (ext == null || !_wastefulForPhotos.contains(ext)) continue;
        if (f.lengthSync() < 300 * 1024) continue;
        offenders.add('${f.path.replaceAll(r'\', '/')}  '
            '${(f.lengthSync() / 1024).toStringAsFixed(0)} KB');
      }
      expect(offenders, isEmpty,
          reason: 'PNG cannot compress photographic content — 1.95 MB became '
              '1.93 MB in the 1.0.0+37 bundle. Use WebP (lossless if it is a '
              'logo):\n${offenders.join('\n')}');
    });

    test('the ceiling is measured against media, not text', () {
      // Pins the fix to this test's own first failure. barangay.json is 4.6 MB
      // on disk and ~370 KB in the bundle; failing on it would have taught
      // whoever hit it that this guard cries wolf.
      final json = File('assets/jsons/philippine-addresses/barangay.json');
      if (json.existsSync()) {
        expect(json.lengthSync(), greaterThan(_maxMediaBytes),
            reason: 'if this file shrank, the case being guarded is gone');
        expect(_mediaExtensions.contains('.json'), isFalse,
            reason: 'text must stay outside the media ceiling');
      }
    });

    test('the campaign creatives are WebP and did not change dimensions', () {
      // Dimensions are load-bearing: the popup CTA hit-rects are stored as
      // fractions of these exact numbers in category_campaign_registry.dart,
      // so a resize during conversion would move every button off its target.
      for (final name in const [
        'aircon_repair_popup_v1',
        'massage_wellness_popup_v1',
        'beauty_wellness_popup_v1',
        'hair_nails_popup_v1',
      ]) {
        final webp = File('assets/images/categories/$name.webp');
        expect(webp.existsSync(), isTrue, reason: '$name.webp is missing');
        expect(File('assets/images/categories/$name.png').existsSync(), isFalse,
            reason: '$name.png should have been replaced, not duplicated');

        // WebP header: 'RIFF' .... 'WEBP', then a VP8/VP8L/VP8X chunk carrying
        // the canvas size. Read it rather than trusting the conversion.
        final b = webp.readAsBytesSync();
        expect(String.fromCharCodes(b.sublist(0, 4)), 'RIFF');
        expect(String.fromCharCodes(b.sublist(8, 12)), 'WEBP');

        final chunk = String.fromCharCodes(b.sublist(12, 16));
        int w = 0, h = 0;
        if (chunk == 'VP8X') {
          w = (b[24] | (b[25] << 8) | (b[26] << 16)) + 1;
          h = (b[27] | (b[28] << 8) | (b[29] << 16)) + 1;
        } else if (chunk == 'VP8 ') {
          w = (b[26] | (b[27] << 8)) & 0x3FFF;
          h = (b[28] | (b[29] << 8)) & 0x3FFF;
        } else if (chunk == 'VP8L') {
          final bits = b[21] | (b[22] << 8) | (b[23] << 16) | (b[24] << 24);
          w = (bits & 0x3FFF) + 1;
          h = ((bits >> 14) & 0x3FFF) + 1;
        }
        expect(w, 941,
            reason: '$name width changed — CTA rects would misalign');
        expect(h, 1672,
            reason: '$name height changed — CTA rects would misalign');
      }
    });

    test('the registry points at the WebP files', () {
      final registry = File(
              'lib/common/presentation/category_campaign/category_campaign_registry.dart')
          .readAsStringSync();
      expect(registry, isNot(contains('popup_v1.png')));
      expect(registry.split('.webp').length - 1, 4,
          reason: 'all four campaigns must reference a .webp asset');
    });
  });
}
