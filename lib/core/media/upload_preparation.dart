/// One place every photo and document the customer uploads passes through.
///
/// ## Why this exists
///
/// Measured on this repository before it did:
///
/// | path | what it sent |
/// | --- | --- |
/// | profile avatar | downscaled to 800px, then **base64 into JSON** — +33% |
/// | `CustomImagePicker` | `pickImage()` with no bounds — a full 12MP frame |
/// | `CarouselImagePicker` | the same, straight from the camera |
/// | `CustomFilePicker` | jpg/pdf/doc/png, **no size limit at all** |
///
/// A modern phone camera produces 3–8 MB per frame. Every one of those bytes
/// is paid for three times: the customer's mobile data, the request the server
/// has to buffer, and the storage it sits in for the life of the booking.
///
/// ## The ceilings are measured, not guessed
///
/// Taken from production on 2026-08-20, in the order a request meets them:
///
///  - **nginx `client_max_body_size 12m`** — the outermost wall. Exceeding it
///    returns a 413 that carries no CORS headers, so the app sees a transport
///    failure and tells the customer to check a connection that is fine.
///  - **`express.json({limit: "10mb"})`** — anything embedded in a JSON body,
///    which for a base64 data URI means the *inflated* size. A 7.5 MB photo is
///    a 10 MB body.
///  - **`MAX_CHAT_ATTACHMENT_BYTES = 10 * 1024 * 1024`** in `chat.controller`.
///
/// Every budget below sits well under the nearest wall, because a client that
/// aims at the limit discovers it by being rejected.
///
/// ## What it does to an image
///
/// Downscale to fit the budget's longest edge, then encode JPEG, then step the
/// quality down until it fits. Three consequences worth stating:
///
///  - **Orientation is baked in.** A phone photo carries its rotation in an
///    EXIF tag rather than in the pixels. Re-encoding without applying it
///    first is the classic way an upright photo arrives on its side, and the
///    customer cannot tell it happened.
///  - **Metadata is dropped.** A fresh encode carries no EXIF, so the GPS
///    coordinates a phone writes into every photo do not travel with it (§58).
///    That is a privacy improvement, not a side effect, and it is asserted.
///  - **Transparency is flattened onto white**, because the output is JPEG.
///    Stated rather than discovered: a transparent PNG would otherwise get a
///    black background.
///
/// ## What it does NOT do to a document
///
/// A PDF is not re-encoded. Rewriting a document the customer chose — a
/// receipt, an ID — risks changing what it says, and no size saving is worth
/// that. Documents are measured against the ceiling and refused honestly when
/// they exceed it, which is strictly better than the 413 they used to get.
library;

import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// How small an upload has to get, and how big it may be at worst.
class UploadBudget {
  const UploadBudget({
    required this.name,
    required this.targetBytes,
    required this.ceilingBytes,
    required this.maxEdge,
    this.startQuality = 85,
    this.minQuality = 45,
  });

  /// Named for the error copy and the telemetry, so a refusal can say which
  /// limit was hit rather than quoting a number with no context.
  final String name;

  /// What compression aims for. Missing it is not a failure — some photographs
  /// resist — as long as the result is under [ceilingBytes].
  final int targetBytes;

  /// The hard wall. Over this, the upload is refused before it is attempted.
  final int ceilingBytes;

  /// Longest edge in pixels after downscaling.
  final int maxEdge;

  final int startQuality;
  final int minQuality;

  /// Anything embedded in a JSON body as a base64 data URI.
  ///
  /// The tightest budget by a wide margin, and deliberately so. Base64 costs
  /// 4 bytes for every 3, so the 10 MB express limit is really a 7.5 MB one —
  /// and an avatar is displayed at about 96 logical pixels. 400 KB is generous
  /// for the job; the previous path could send five megabytes of JSON for it.
  static const avatar = UploadBudget(
    name: 'profile photo',
    targetBytes: 300 * 1024,
    ceilingBytes: 700 * 1024,
    maxEdge: 720,
  );

  /// A photo sent into a booking conversation.
  ///
  /// The server allows 10 MB. This aims two orders of magnitude below it: the
  /// picture has to show a broken tap or a finished repair on a phone screen,
  /// not survive printing.
  static const chatPhoto = UploadBudget(
    name: 'photo',
    targetBytes: 800 * 1024,
    ceilingBytes: 3 * 1024 * 1024,
    maxEdge: 1600,
  );

  /// Evidence attached to a support ticket or a booking — a receipt, a photo
  /// of damage. Slightly larger, because detail can be the point.
  static const evidencePhoto = UploadBudget(
    name: 'photo',
    targetBytes: 1024 * 1024,
    ceilingBytes: 4 * 1024 * 1024,
    maxEdge: 2000,
  );

  /// A document, which is never re-encoded — only measured.
  ///
  /// Under nginx's 12 MB wall with room to spare, because the multipart
  /// envelope and the form fields are counted against it too.
  static const document = UploadBudget(
    name: 'document',
    targetBytes: 8 * 1024 * 1024,
    ceilingBytes: 8 * 1024 * 1024,
    maxEdge: 0,
  );
}

/// What came of preparing an upload.
sealed class UploadPreparation {
  const UploadPreparation();
}

/// Ready to send.
class UploadReady extends UploadPreparation {
  const UploadReady({
    required this.bytes,
    required this.contentType,
    required this.originalBytes,
    required this.recompressed,
  });

  final Uint8List bytes;
  final String contentType;

  /// What the customer chose, before anything was done to it. Kept so a caller
  /// can report the saving rather than assert one.
  final int originalBytes;

  /// False for a document, which is passed through untouched.
  final bool recompressed;

  int get bytesSent => bytes.length;

  /// 0.0 when nothing was saved. Never negative: if an encode came out larger
  /// than the original — a small PNG re-encoded as JPEG can — the original is
  /// what gets sent, so this cannot go below zero by construction.
  double get savedFraction =>
      originalBytes == 0 ? 0 : 1 - (bytes.length / originalBytes);

  String get savedSummary =>
      '${(originalBytes / 1024).round()} KB → ${(bytes.length / 1024).round()} KB';
}

/// Too big to send, and compression could not fix it.
///
/// A refusal the app can render. The alternative is the request going out and
/// nginx answering 413 with no CORS headers, which reaches the app as a
/// transport error and gets reported to the customer as a connection problem.
class UploadTooLarge extends UploadPreparation {
  const UploadTooLarge({
    required this.originalBytes,
    required this.smallestBytes,
    required this.budget,
  });

  final int originalBytes;

  /// The smallest this could be made. For a document it equals
  /// [originalBytes], because documents are not re-encoded.
  final int smallestBytes;

  final UploadBudget budget;

  /// Customer-facing, and actionable: it says what to do, not what failed.
  String get message {
    final limit = (budget.ceilingBytes / (1024 * 1024)).toStringAsFixed(0);
    return budget.maxEdge == 0
        ? 'This ${budget.name} is larger than $limit MB. Please choose a '
            'smaller file.'
        : 'This ${budget.name} is too large to send even after compressing. '
            'Please choose another.';
  }
}

/// The bytes are not an image this build can decode.
class UploadUnsupported extends UploadPreparation {
  const UploadUnsupported({required this.originalBytes});

  final int originalBytes;

  String get message =>
      'That file could not be read. Please choose a JPG or PNG.';
}

/// Prepares bytes for upload.
///
/// Pure Dart and synchronous at heart, so it is exercised in unit tests rather
/// than only on a device. [prepareImage] is deliberately CPU-bound work: run it
/// through `compute` from a caller that cares about a dropped frame.
abstract final class UploadCompressor {
  /// Compresses an image to fit [budget].
  ///
  /// Returns [UploadReady] with the smaller of the compressed and original
  /// bytes — a small PNG can encode LARGER as JPEG, and sending the bigger of
  /// the two to satisfy a compression step would defeat the point.
  static UploadPreparation prepareImage(
    Uint8List original, {
    UploadBudget budget = UploadBudget.chatPhoto,
  }) {
    if (original.isEmpty) {
      return const UploadUnsupported(originalBytes: 0);
    }

    final decoded = img.decodeImage(original);
    if (decoded == null) {
      return UploadUnsupported(originalBytes: original.length);
    }

    // Orientation is already in the pixels by this point.
    //
    // A phone writes rotation into an EXIF tag rather than into the pixels, and
    // a re-encode that ignored it would produce an upright photo lying on its
    // side with nothing on screen to say why. This used to call
    // `img.bakeOrientation` for that — measured, `decodeImage` has ALREADY
    // applied it: a 400x800 JPEG tagged orientation 6 decodes as 800x400 with
    // the tag cleared, and baking again copies the whole image to do nothing.
    //
    // It was removed rather than kept as insurance because a mutation run
    // proved the cost bought no protection: deleting the call failed no test,
    // which is the definition of dead work. What DOES protect the customer is
    // clearing the metadata below, so a stale tag cannot rotate the photo a
    // second time in a viewer. `upload_preparation_test.dart` pins the
    // end-to-end outcome, and says which layer it is really pinning.
    var working = decoded;

    if (budget.maxEdge > 0) {
      final longest =
          working.width > working.height ? working.width : working.height;
      if (longest > budget.maxEdge) {
        working = working.width >= working.height
            ? img.copyResize(working, width: budget.maxEdge)
            : img.copyResize(working, height: budget.maxEdge);
      }
    }

    // JPEG has no alpha. Flattening onto white is the stated behaviour; the
    // alternative is a transparent PNG arriving with a black background,
    // which looks like corruption rather than a format choice.
    if (working.hasAlpha) {
      final flattened = img.Image(
        width: working.width,
        height: working.height,
        numChannels: 3,
      );
      img.fill(flattened, color: img.ColorRgb8(255, 255, 255));
      img.compositeImage(flattened, working);
      working = flattened;
    }

    // Drop the metadata, AFTER orientation has been baked into the pixels.
    //
    // Not automatic, and measured rather than assumed: `bakeOrientation` and
    // `copyResize` both carry `exif` forward, and `encodeJpg` writes it back
    // out — so a re-encoded photo arrived with the GPS coordinates the phone
    // wrote into it still attached. A test asserted this was already true, and
    // it was not (§58).
    //
    // Clearing also removes the orientation tag itself, which now MUST go: the
    // rotation is in the pixels, and a viewer that applied the tag as well
    // would turn the photo a second time.
    working.exif = img.ExifData();

    var quality = budget.startQuality;
    var encoded = Uint8List.fromList(img.encodeJpg(working, quality: quality));

    // Step the quality down before touching the dimensions: a customer notices
    // a smaller picture long before they notice a softer one.
    while (encoded.length > budget.targetBytes && quality > budget.minQuality) {
      quality -= 10;
      if (quality < budget.minQuality) quality = budget.minQuality;
      encoded = Uint8List.fromList(img.encodeJpg(working, quality: quality));
    }

    // Still over: halve the edge and try once more. Twice, at most — a third
    // pass buys little and costs a decode each time.
    var halvings = 0;
    while (encoded.length > budget.targetBytes && halvings < 2) {
      halvings++;
      final width = (working.width / 2).round();
      if (width < 200) break;
      working = img.copyResize(working, width: width);
      encoded = Uint8List.fromList(
        img.encodeJpg(working, quality: budget.minQuality),
      );
    }

    if (encoded.length > budget.ceilingBytes) {
      return UploadTooLarge(
        originalBytes: original.length,
        smallestBytes: encoded.length,
        budget: budget,
      );
    }

    // Never send MORE than the customer chose. A 4 KB PNG icon re-encodes to
    // something larger, and "we compressed it" would then be false.
    if (encoded.length >= original.length) {
      return UploadReady(
        bytes: original,
        contentType: _contentTypeOf(original),
        originalBytes: original.length,
        recompressed: false,
      );
    }

    return UploadReady(
      bytes: encoded,
      contentType: 'image/jpeg',
      originalBytes: original.length,
      recompressed: true,
    );
  }

  /// Measures a document against [budget]. Never rewrites it.
  static UploadPreparation prepareDocument(
    Uint8List original, {
    required String contentType,
    UploadBudget budget = UploadBudget.document,
  }) {
    if (original.length > budget.ceilingBytes) {
      return UploadTooLarge(
        originalBytes: original.length,
        smallestBytes: original.length,
        budget: budget,
      );
    }
    return UploadReady(
      bytes: original,
      contentType: contentType,
      originalBytes: original.length,
      recompressed: false,
    );
  }

  /// Whether [filename] names something [prepareImage] should handle.
  ///
  /// Extension only, and only to CHOOSE a path — never to trust one. The
  /// decoder is the authority on whether bytes are an image, and it answers by
  /// returning null.
  static bool looksLikeImage(String filename) {
    final lower = filename.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.heic') ||
        lower.endsWith('.heif') ||
        lower.endsWith('.bmp') ||
        lower.endsWith('.gif');
  }

  /// Sniffed from magic bytes, not from the name (§44). Only reached when the
  /// original is being sent unchanged.
  static String _contentTypeOf(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 12 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return 'application/octet-stream';
  }
}
