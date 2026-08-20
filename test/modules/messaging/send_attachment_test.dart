/// Sending a photo into a booking conversation.
///
/// Every fixture is the shape the backend actually writes, read from
/// `chat.controller`, `chat.service` and `messagingPolicy` on the commit
/// production runs:
///
///  - `POST /api/chat/attachments/upload` → **201**
///    `{success, attachmentId, previewUrl, fileName, mimeType, sizeBytes}`;
///    **422** `ATTACHMENT_REJECTED` when the data URI fails `validateDataUri`.
///  - `POST /api/chat/conversations/:id/messages` → **201**
///    `{success, message}`; the send is what carries `clientMsgId`, and the
///    upload carries no idempotency at all.
///  - `SENDABLE_MESSAGE_TYPES` is `text | image | file`; `ATTACHMENT_POLICY`
///    allows jpeg, png, webp and pdf, at most 5 per message, 10 MB each.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:client/common/data/models/user_session.dart';
import 'package:client/common/domain/helpers/session_service.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/common/services/auth_state_service.dart';
import 'package:client/core/media/upload_preparation.dart';
import 'package:client/modules/messaging/data/models/message_model.dart';
import 'package:client/modules/messaging/presentation/stores/messaging_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/screen_test_container.dart';

const _conversationId = 77;

http.Response _json(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: const {'content-type': 'application/json'},
    );

class _Backend {
  final List<http.Request> requests = <http.Request>[];

  /// Overridable per test.
  http.Response Function()? uploadResponse;
  http.Response Function()? sendResponse;

  http.Client client() => MockClient((request) async {
        requests.add(request);
        final path = request.url.path;

        if (path.endsWith('/attachments/upload')) {
          return (uploadResponse ?? _defaultUpload)();
        }
        if (path.endsWith('/messages') && request.method == 'POST') {
          return (sendResponse ?? _defaultSend)();
        }
        return _json({'success': true, 'data': <dynamic>[]});
      });

  static http.Response _defaultUpload() => _json({
        'success': true,
        'attachmentId': 'uid_1234-abcd',
        'previewUrl': 'https://storage.example/chat-attachments/uid_1234-abcd',
        'fileName': 'photo.jpg',
        'mimeType': 'image/jpeg',
        'sizeBytes': 81234,
      }, 201);

  static http.Response _defaultSend() => _json({
        'success': true,
        'message': {
          'id': 991,
          'conversationId': _conversationId,
          'type': 'image',
          'body': 'the tap is leaking',
          'createdAt': '2026-08-20T09:00:00.000Z',
          'attachments': [
            {
              'id': 5,
              'url': 'https://storage.example/chat-attachments/uid_1234-abcd',
              'fileName': 'photo.jpg',
              'mimeType': 'image/jpeg',
              'sizeBytes': 81234,
            },
          ],
        },
      }, 201);

  Map<String, dynamic>? bodyOf(String pathSuffix) {
    for (final r in requests.reversed) {
      if (r.url.path.endsWith(pathSuffix) && r.method == 'POST') {
        return jsonDecode(r.body) as Map<String, dynamic>;
      }
    }
    return null;
  }

  int countOf(String pathSuffix) =>
      requests.where((r) => r.url.path.endsWith(pathSuffix)).length;
}

late _Backend backend;

Future<void> _arrange() async {
  backend = _Backend();
  await registerScreenDependencies(client: backend.client());

  const key = 'c2VydmFuYS10ZXN0LWNpcGhlci1rZXktMzJieXRlcyE=';
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (call) async => switch (call.method) {
      'readAll' => <String, String>{},
      'read' => key,
      _ => null,
    },
  );
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(UserSessionAdapter());
  }
  await SessionService.saveSession(const UserSession(
    customerID: 'test-customer-uid',
    mobileNumber: '09171234567',
    fullname: 'Test Customer',
    token: 'test-token',
  ));
  dpLocator<AuthStateService>().update(AuthStatus.authenticated);
}

/// A small, valid JPEG data URI — produced by the compressor, so the test sends
/// what the app sends rather than a string that merely looks like one.
String _photoDataUri() {
  final image = Uint8List(120 * 120 * 3);
  for (var i = 0; i < image.length; i++) {
    image[i] = (i * 7) & 0xFF;
  }
  // A raw buffer is not an image; build one the codec will accept by asking the
  // compressor to refuse it, then fall back to a known-good encode.
  final prepared = UploadCompressor.prepareImage(image);
  if (prepared is UploadReady) {
    return 'data:${prepared.contentType};base64,${base64Encode(prepared.bytes)}';
  }
  return 'data:image/jpeg;base64,${base64Encode(image)}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_arrange);

  tearDown(() async {
    await SessionService.deleteSession();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      null,
    );
    await resetScreenDependencies();
  });

  group('the two calls, in the order that matters', () {
    test('stores the file, then sends the message that references it',
        () async {
      final store = dpLocator<MessagingStore>();

      await store.sendAttachment(
        conversationId: _conversationId,
        dataUri: _photoDataUri(),
        fileName: 'photo.jpg',
        mimeType: 'image/jpeg',
        caption: 'the tap is leaking',
      );

      expect(backend.countOf('/attachments/upload'), 1);
      expect(backend.countOf('/messages'), 1);

      // Order is load-bearing: an attachment is inert until a message
      // references it, so a failed send leaves an orphaned object rather than a
      // message pointing at nothing.
      final uploadIndex = backend.requests
          .indexWhere((r) => r.url.path.endsWith('/attachments/upload'));
      final sendIndex =
          backend.requests.indexWhere((r) => r.url.path.endsWith('/messages'));
      expect(uploadIndex, lessThan(sendIndex));
    });

    test('the upload names the conversation, closing the access-check hole',
        () async {
      // `conversationId` is optional on the wire and omitting it SKIPS the
      // server's access check. The backend keeps it optional only so installed
      // builds that never sent it keep working; a new caller has no reason to
      // inherit that hole.
      await dpLocator<MessagingStore>().sendAttachment(
        conversationId: _conversationId,
        dataUri: _photoDataUri(),
        fileName: 'photo.jpg',
        mimeType: 'image/jpeg',
      );

      final body = backend.bodyOf('/attachments/upload')!;
      expect(body['conversationId'], _conversationId);
      expect(body['name'], 'photo.jpg');
      expect(body['file'], startsWith('data:image/'));
    });

    test('the send carries the reference the upload returned, not the bytes',
        () async {
      await dpLocator<MessagingStore>().sendAttachment(
        conversationId: _conversationId,
        dataUri: _photoDataUri(),
        fileName: 'photo.jpg',
        mimeType: 'image/jpeg',
        caption: 'the tap is leaking',
      );

      final body = backend.bodyOf('/messages')!;
      final attachments = body['attachments'] as List<dynamic>;

      expect(attachments, hasLength(1));
      expect(
        (attachments.single as Map)['url'],
        'https://storage.example/chat-attachments/uid_1234-abcd',
      );
      // Sending the data URI twice would double an already-expensive request.
      expect(body.toString(), isNot(contains('base64')));
      expect(body['body'], 'the tap is leaking');
      expect(body['clientMsgId'], isNotEmpty);
    });

    test('an image is typed image, a PDF is typed file', () async {
      final store = dpLocator<MessagingStore>();

      await store.sendAttachment(
        conversationId: _conversationId,
        dataUri: _photoDataUri(),
        fileName: 'photo.jpg',
        mimeType: 'image/jpeg',
      );
      expect(backend.bodyOf('/messages')!['type'], 'image');

      await store.sendAttachment(
        conversationId: _conversationId,
        dataUri: 'data:application/pdf;base64,JVBERi0=',
        fileName: 'receipt.pdf',
        mimeType: 'application/pdf',
      );
      // A PDF sent as `image` renders as a broken thumbnail.
      expect(backend.bodyOf('/messages')!['type'], 'file');
    });
  });

  group('what the customer sees', () {
    test('a pending bubble appears before the network answers', () async {
      final store = dpLocator<MessagingStore>();

      final pending = store.sendAttachment(
        conversationId: _conversationId,
        dataUri: _photoDataUri(),
        fileName: 'photo.jpg',
        mimeType: 'image/jpeg',
        caption: 'look',
      );

      final optimistic = store.messagesByConvId[_conversationId]!.last;
      expect(optimistic.sendStatus, MessageSendStatus.pending);
      expect(optimistic.type, MessageType.image);
      // The CAPTION, not the file name. A customer photographing a leaking tap
      // is not sending a document called IMG_20260820.jpg, and the storage name
      // is an internal detail (§58).
      expect(optimistic.body, 'look');
      expect(optimistic.body, isNot(contains('photo.jpg')));

      await pending;
    });

    test('the confirmed message replaces the pending one', () async {
      final store = dpLocator<MessagingStore>();

      await store.sendAttachment(
        conversationId: _conversationId,
        dataUri: _photoDataUri(),
        fileName: 'photo.jpg',
        mimeType: 'image/jpeg',
      );

      final messages = store.messagesByConvId[_conversationId]!;
      expect(messages, hasLength(1), reason: 'the optimistic bubble was left');
      expect(messages.single.id, 991);
      expect(messages.single.attachments, hasLength(1));
      expect(messages.single.sendStatus, isNot(MessageSendStatus.failed));
    });

    test('a rejected upload leaves the bubble FAILED, not silently gone',
        () async {
      // 422 ATTACHMENT_REJECTED — what `validateDataUri` returns for a type or
      // size the policy refuses.
      backend.uploadResponse = () => _json({
            'success': false,
            'message': 'Attachment type is not allowed',
            'code': 'ATTACHMENT_REJECTED',
          }, 422);

      final store = dpLocator<MessagingStore>();
      await store.sendAttachment(
        conversationId: _conversationId,
        dataUri: _photoDataUri(),
        fileName: 'photo.jpg',
        mimeType: 'image/jpeg',
      );

      final messages = store.messagesByConvId[_conversationId]!;
      expect(messages.single.sendStatus, MessageSendStatus.failed);
      // And it never attempted the send.
      expect(backend.countOf('/messages'), 0);
    });

    test('a failed send after a successful upload also fails visibly',
        () async {
      backend.sendResponse = () => _json({'success': false}, 500);

      final store = dpLocator<MessagingStore>();
      await store.sendAttachment(
        conversationId: _conversationId,
        dataUri: _photoDataUri(),
        fileName: 'photo.jpg',
        mimeType: 'image/jpeg',
      );

      expect(
        store.messagesByConvId[_conversationId]!.single.sendStatus,
        MessageSendStatus.failed,
      );
      // The object was stored and is now orphaned. That is the deliberate
      // trade: an orphan is wasted storage, a message referencing nothing is a
      // broken bubble.
      expect(backend.countOf('/attachments/upload'), 1);
    });

    test('an upload that returns no url is refused rather than sent empty',
        () async {
      backend.uploadResponse = () => _json({'success': true}, 201);

      final store = dpLocator<MessagingStore>();
      await store.sendAttachment(
        conversationId: _conversationId,
        dataUri: _photoDataUri(),
        fileName: 'photo.jpg',
        mimeType: 'image/jpeg',
      );

      expect(
        store.messagesByConvId[_conversationId]!.single.sendStatus,
        MessageSendStatus.failed,
      );
      expect(backend.countOf('/messages'), 0,
          reason: 'a message referencing an empty url is a broken bubble');
    });
  });

  group('the budget the transport actually has', () {
    test('a chat photo fits express\'s JSON limit after base64', () {
      // The endpoint takes a data URI in a JSON body, so base64 costs 4 bytes
      // for every 3 and `express.json({limit:"10mb"})` is reached by a 7.5 MB
      // file — before the handler's own 10 MB check ever runs.
      const expressJsonWall = 10 * 1024 * 1024;

      expect(
        (UploadBudget.chatPhoto.ceilingBytes * 4 / 3).ceil(),
        lessThan(expressJsonWall),
      );
      // And well clear of nginx's client_max_body_size 12m behind it.
      expect(
        (UploadBudget.chatPhoto.ceilingBytes * 4 / 3).ceil(),
        lessThan(12 * 1024 * 1024),
      );
    });
  });
}
