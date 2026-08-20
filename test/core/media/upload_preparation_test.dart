/// The upload compressor, exercised on real encoded bytes.
///
/// Every fixture here is built by encoding an actual image and handed to the
/// compressor as bytes, so each test performs a genuine decode → transform →
/// encode round trip. A stubbed codec would agree with the compressor by
/// construction and could not tell us whether a photo survives it.
library;

import 'dart:typed_data';

import 'package:client/core/media/upload_preparation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// A photograph-like image: smooth gradients plus noise, so it does not
/// compress to nothing the way a flat colour would and the numbers below mean
/// something.
img.Image _photo({required int width, required int height}) {
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      // Deterministic pseudo-noise. `Math.random` would make a size assertion
      // flake, and this file asserts sizes.
      final n = ((x * 7919) ^ (y * 104729)) & 0x3F;
      image.setPixelRgb(
        x,
        y,
        (x * 255 ~/ width + n) & 0xFF,
        (y * 255 ~/ height + n) & 0xFF,
        ((x + y) * 255 ~/ (width + height) + n) & 0xFF,
      );
    }
  }
  return image;
}

Uint8List _png(img.Image image) => Uint8List.fromList(img.encodePng(image));
Uint8List _jpg(img.Image image, {int quality = 95}) =>
    Uint8List.fromList(img.encodeJpg(image, quality: quality));

void main() {
  group('a camera-sized photo is made sendable', () {
    test('a 12MP frame is reduced by well over 90%', () {
      // 4032x3024 is what a current phone produces. Encoded at high quality it
      // is the multi-megabyte payload this whole mechanism exists for.
      final original = _jpg(_photo(width: 4032, height: 3024));

      final result = UploadCompressor.prepareImage(
        original,
        budget: UploadBudget.chatPhoto,
      );

      expect(result, isA<UploadReady>());
      final ready = result as UploadReady;

      expect(ready.recompressed, isTrue);
      expect(ready.bytesSent, lessThan(UploadBudget.chatPhoto.targetBytes),
          reason: 'the budget is the point: ${ready.savedSummary}');
      expect(ready.savedFraction, greaterThan(0.9),
          reason: 'saved only ${(ready.savedFraction * 100).round()}%');
      expect(ready.contentType, 'image/jpeg');
    });

    test('the longest edge is bounded, whichever way round the photo is', () {
      for (final source in [
        _photo(width: 4032, height: 3024), // landscape
        _photo(width: 3024, height: 4032), // portrait
      ]) {
        final result = UploadCompressor.prepareImage(
          _jpg(source),
          budget: UploadBudget.chatPhoto,
        );

        final decoded = img.decodeImage((result as UploadReady).bytes)!;
        final longest =
            decoded.width > decoded.height ? decoded.width : decoded.height;

        expect(longest, lessThanOrEqualTo(UploadBudget.chatPhoto.maxEdge));
        // And the shape is kept — a squashed photo is a different defect from
        // a large one.
        expect(
          decoded.width / decoded.height,
          closeTo(source.width / source.height, 0.02),
        );
      }
    });

    test('an avatar is squeezed far harder than a chat photo', () {
      final original = _jpg(_photo(width: 4032, height: 3024));

      final avatar = UploadCompressor.prepareImage(
        original,
        budget: UploadBudget.avatar,
      ) as UploadReady;
      final chat = UploadCompressor.prepareImage(
        original,
        budget: UploadBudget.chatPhoto,
      ) as UploadReady;

      expect(avatar.bytesSent, lessThan(chat.bytesSent));
      expect(avatar.bytesSent, lessThan(UploadBudget.avatar.targetBytes));
    });

    test('an avatar still fits express\'s JSON limit after base64', () {
      // The avatar path embeds a data URI in a JSON body, and base64 costs 4
      // bytes for every 3 — so the 10 MB server limit is really 7.5 MB. This
      // is the assertion that keeps the budget honest about the transport it
      // is actually for.
      final ready = UploadCompressor.prepareImage(
        _jpg(_photo(width: 4032, height: 3024)),
        budget: UploadBudget.avatar,
      ) as UploadReady;

      final base64Bytes = (ready.bytesSent * 4 / 3).ceil();
      expect(base64Bytes, lessThan(10 * 1024 * 1024));
      // And by a wide margin, not by a hair.
      expect(base64Bytes, lessThan(1024 * 1024));
    });
  });

  group('what compression must not quietly change', () {
    test('a sideways photo is not uploaded sideways', () {
      // A phone records rotation in an EXIF tag rather than in the pixels, and
      // a re-encode that ignored it would upload an upright photo lying on its
      // side with nothing on screen to say why.
      //
      // ⚠ This pins the DECODER, not our code. `decodeImage` applies the
      // orientation itself — measured: a 400x800 JPEG tagged orientation 6
      // decodes as 800x400 with the tag already cleared. An earlier version of
      // the compressor called `bakeOrientation` for this, and deleting that
      // call failed no test, which is how the redundancy was found.
      //
      // Kept because the outcome is what the customer sees, and it would fail
      // if the decode path were ever swapped for one that does not do it. It
      // is not evidence that the compressor handles orientation.
      final upright = _photo(width: 400, height: 800);
      final encoded = img.encodeJpg(upright, quality: 95);
      final withExif = img.decodeJpg(Uint8List.fromList(encoded))!;
      withExif.exif.imageIfd.orientation = 6;
      final rotatedBytes =
          Uint8List.fromList(img.encodeJpg(withExif, quality: 95));

      final ready = UploadCompressor.prepareImage(
        rotatedBytes,
        budget: UploadBudget.evidencePhoto,
      ) as UploadReady;
      final result = img.decodeImage(ready.bytes)!;

      // Orientation 6 means "the stored pixels are rotated": a 400x800 frame
      // is displayed as 800x400. Baking it makes the pixels match.
      expect(result.width, greaterThan(result.height),
          reason: 'the orientation tag was dropped instead of applied — the '
              'photo will arrive on its side');
    });

    test('EXIF metadata does not travel with the photo', () {
      // A phone writes GPS coordinates into every picture it takes. A fresh
      // encode carries none, which is a privacy improvement (§58) rather than
      // an accident — so it is asserted rather than assumed.
      //
      // Written with numeric tag ids and `IfdValue` wrappers. Assigning a bare
      // double to a string key — `gpsIfd['GPSLatitude'] = 14.5` — is silently
      // dropped, so the first version of this fixture carried no GPS tag at
      // all and the assertion below would have passed against a photo that
      // never had one. The guard is what caught it.
      final decoded = img.decodeJpg(_jpg(_photo(width: 2000, height: 1500)))!;
      decoded.exif.gpsIfd[0x0001] = img.IfdValueAscii('N');
      decoded.exif.gpsIfd[0x0002] = img.IfdValueRational(14, 1);
      final tagged = Uint8List.fromList(img.encodeJpg(decoded, quality: 95));

      // The fixture must actually carry what the assertion is about.
      expect(img.decodeJpg(tagged)!.exif.gpsIfd.isEmpty, isFalse,
          reason: 'the fixture has no GPS tag, so the test proves nothing');

      final ready = UploadCompressor.prepareImage(
        tagged,
        budget: UploadBudget.chatPhoto,
      ) as UploadReady;

      expect(ready.recompressed, isTrue,
          reason: 'nothing was re-encoded, so nothing could have been dropped');
      expect(img.decodeJpg(ready.bytes)!.exif.gpsIfd.isEmpty, isTrue,
          reason: "the customer's coordinates were uploaded with their photo");
    });

    test('a transparent image is flattened onto white, not onto black', () {
      // Camera-sized, so the downscale to 1600px alone guarantees the JPEG
      // beats the PNG and the compressor actually re-encodes. A same-size
      // fixture does not: measured at 1200x1200, PNG won for both a smooth
      // gradient and for noise, the compressor correctly returned the
      // ORIGINAL, and this test then read the source PNG's own transparent
      // corner and reported the flattening as broken.
      final withAlpha =
          _photo(width: 3000, height: 3000).convert(numChannels: 4, alpha: 255);

      // Set directly, NOT with `fillRect(color: ColorRgba8(0,0,0,0))`.
      // fillRect COMPOSITES, so filling with a fully transparent colour is a
      // no-op — the band stayed opaque, the corner kept the photo's own dark
      // pixel, and the failure read exactly like a broken flatten. Three
      // fixtures in a row lied before this was measured.
      for (var y = 0; y < 500; y++) {
        for (var x = 0; x < withAlpha.width; x++) {
          withAlpha.setPixelRgba(x, y, 0, 0, 0, 0);
        }
      }
      expect(withAlpha.getPixel(5, 5).a, 0,
          reason: 'the fixture is not transparent, so it proves nothing');

      final ready = UploadCompressor.prepareImage(
        _png(withAlpha),
        budget: UploadBudget.chatPhoto,
      ) as UploadReady;

      expect(ready.recompressed, isTrue,
          reason: 'the original was returned, so nothing was flattened');

      final corner = img.decodeImage(ready.bytes)!.getPixel(5, 5);
      expect(corner.r, greaterThan(240));
      expect(corner.g, greaterThan(240));
      expect(corner.b, greaterThan(240));
    });

    test('a small image is never made bigger', () {
      // A 64x64 PNG icon re-encodes to something LARGER as JPEG. Sending the
      // bigger of the two to satisfy a compression step would make the whole
      // mechanism cost bytes instead of saving them.
      final tiny = _png(_photo(width: 64, height: 64));

      final ready = UploadCompressor.prepareImage(
        tiny,
        budget: UploadBudget.chatPhoto,
      ) as UploadReady;

      expect(ready.bytesSent, lessThanOrEqualTo(tiny.length));
      expect(ready.savedFraction, greaterThanOrEqualTo(0));
      if (!ready.recompressed) {
        expect(ready.bytes, same(tiny));
        expect(ready.contentType, 'image/png',
            reason: 'sniffed from magic bytes, not from a filename');
      }
    });
  });

  group('what cannot be sent is refused before it is attempted', () {
    test('a document over the ceiling is refused, not re-encoded', () {
      final huge = Uint8List(9 * 1024 * 1024);

      final result = UploadCompressor.prepareDocument(
        huge,
        contentType: 'application/pdf',
      );

      expect(result, isA<UploadTooLarge>());
      final refused = result as UploadTooLarge;
      // Not rewritten: a PDF the customer chose is not the app's to alter.
      expect(refused.smallestBytes, huge.length);
      expect(refused.message, contains('8 MB'));
      expect(refused.message, contains('smaller file'));
    });

    test('a document under the ceiling passes through byte for byte', () {
      final pdf = Uint8List.fromList(
        List<int>.generate(400 * 1024, (i) => i & 0xFF),
      );

      final ready = UploadCompressor.prepareDocument(
        pdf,
        contentType: 'application/pdf',
      ) as UploadReady;

      expect(ready.bytes, same(pdf));
      expect(ready.recompressed, isFalse);
      expect(ready.contentType, 'application/pdf');
    });

    test('bytes that are not an image say so rather than throwing', () {
      final notAnImage = Uint8List.fromList(
        'this is a text file pretending to be a photo'.codeUnits,
      );

      final result = UploadCompressor.prepareImage(notAnImage);

      expect(result, isA<UploadUnsupported>());
      expect((result as UploadUnsupported).message, contains('JPG or PNG'));
    });

    test('an empty selection is unsupported, not a crash', () {
      expect(UploadCompressor.prepareImage(Uint8List(0)),
          isA<UploadUnsupported>());
    });

    test('the refusal is customer-facing copy, not a diagnostic', () {
      final refused = UploadCompressor.prepareDocument(
        Uint8List(20 * 1024 * 1024),
        contentType: 'application/pdf',
      ) as UploadTooLarge;

      // The alternative to this message is nginx answering 413 with no CORS
      // headers, which reaches the app as a transport error and gets reported
      // as a connection problem to a customer whose connection is fine.
      expect(refused.message, isNot(contains('413')));
      expect(refused.message, isNot(contains('nginx')));
      expect(refused.message, isNot(contains('ceilingBytes')));
    });
  });

  group('the budgets sit under the walls that were measured', () {
    // Production, 2026-08-20: nginx client_max_body_size 12m,
    // express.json limit 10mb, MAX_CHAT_ATTACHMENT_BYTES 10 MB.
    const nginxWall = 12 * 1024 * 1024;
    const expressJsonWall = 10 * 1024 * 1024;

    test('no budget aims at a wall', () {
      for (final budget in const [
        UploadBudget.avatar,
        UploadBudget.chatPhoto,
        UploadBudget.evidencePhoto,
        UploadBudget.document,
      ]) {
        expect(budget.ceilingBytes, lessThan(nginxWall),
            reason: '${budget.name} could be refused by nginx');
        expect(budget.targetBytes, lessThanOrEqualTo(budget.ceilingBytes),
            reason: '${budget.name} targets more than it allows');
      }
    });

    test('the avatar ceiling survives base64 inflation into a JSON body', () {
      expect((UploadBudget.avatar.ceilingBytes * 4 / 3).ceil(),
          lessThan(expressJsonWall));
    });

    test('looksLikeImage chooses a path and never grants trust', () {
      expect(UploadCompressor.looksLikeImage('receipt.HEIC'), isTrue);
      expect(UploadCompressor.looksLikeImage('scan.pdf'), isFalse);
      // The decoder is the authority, and it says no by returning null — which
      // is what makes a .jpg full of text an UploadUnsupported rather than a
      // corrupt upload.
      expect(
        UploadCompressor.prepareImage(
          Uint8List.fromList('not really a jpeg'.codeUnits),
        ),
        isA<UploadUnsupported>(),
      );
    });
  });
}
