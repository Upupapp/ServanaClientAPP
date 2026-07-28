import 'dart:convert';
import 'dart:io';

import 'package:client/common/data/backend/servana_api_client.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    registerFallbackValue(Uri());
    registerFallbackValue(<String, String>{});
    registerFallbackValue(http.Request('GET', Uri()));

    // Initialize Hive in a temp directory so HiveHelper.openBox() works.
    hiveDir = Directory.systemTemp.createTempSync('servana_api_client_test');
    Hive.init(hiveDir.path);

    // Stub flutter_secure_storage so retrieveCipherKey() gets a usable value
    // instead of hitting the real Keychain/EncryptedSharedPreferences.
    // The 'read' handler returns null (key not yet stored) → retrieveCipherKey
    // generates a new key and calls 'write', which this handler also absorbs.
    // All other method calls (delete, deleteAll, etc.) are similarly swallowed.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (_) async => null,
    );
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      null,
    );
    try {
      hiveDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  late MockHttpClient mockHttp;
  late ServanaApiClient client;

  setUp(() {
    mockHttp = MockHttpClient();
    client = ServanaApiClient(
      baseUrl: 'https://api.test.example',
      client: mockHttp,
    );
  });

  // Helper: stub mockHttp.send() to return a successful empty-body response.
  // The actual call path is:
  //   ServanaApiClient._client (a _TimeoutClient wrapping mockHttp)
  //     -> _TimeoutClient.send()  [inherited BaseClient.get() → this.send()]
  //       -> mockHttp.send(request)
  // Therefore we must mock send(), not get(), and capture the BaseRequest.
  void stubSend({String body = '{}', int status = 200}) {
    when(() => mockHttp.send(any())).thenAnswer((_) async {
      return http.StreamedResponse(
        Stream.value(utf8.encode(body)),
        status,
      );
    });
  }

  group('ServanaApiClient.listOptionsWithAddons', () {
    test('GET path includes service id in the correct path segment', () async {
      stubSend();

      await client.listOptionsWithAddons(serviceId: 7);

      final captured = verify(() => mockHttp.send(captureAny()))
          .captured
          .single as http.BaseRequest;

      expect(
        captured.url.path,
        '/api/services/7/options-with-addons',
        reason:
            'serviceId must be interpolated into the URL path, not a query parameter',
      );
      expect(
        captured.url.queryParameters,
        isEmpty,
        reason: 'No query parameters — serviceId belongs in the path only',
      );
    });

    test('uses a different service id correctly', () async {
      stubSend();

      await client.listOptionsWithAddons(serviceId: 42);

      final captured = verify(() => mockHttp.send(captureAny()))
          .captured
          .single as http.BaseRequest;

      expect(captured.url.path, '/api/services/42/options-with-addons');
    });

    test('sends a GET request, not POST or other method', () async {
      stubSend();

      await client.listOptionsWithAddons(serviceId: 1);

      final captured = verify(() => mockHttp.send(captureAny()))
          .captured
          .single as http.BaseRequest;

      expect(captured.method, 'GET');
    });

    test('request targets the configured base URL host', () async {
      stubSend();

      await client.listOptionsWithAddons(serviceId: 5);

      final captured = verify(() => mockHttp.send(captureAny()))
          .captured
          .single as http.BaseRequest;

      expect(captured.url.host, 'api.test.example');
    });
  });
}
