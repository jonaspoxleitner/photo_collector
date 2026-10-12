import 'dart:convert';
import 'dart:typed_data';

import 'package:app/models/event_config.dart';
import 'package:app/services/storage/s3/upload_error.dart';
import 'package:app/services/storage/s3_client/s3_client_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:s3_client/s3_client.dart';

/// Exercises the real `package:s3_client` request-signing pipeline against
/// a fake HTTP client, asserting the request shape and the
/// [UploadException] error contract.
void main() {
  const config = EventConfig(
    accessKeyId: 'AKIAIOSFODNN7EXAMPLE',
    secretKey: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
    bucket: 'wedding-20261025',
    region: 'eu-central-1',
  );

  S3CredentialsProvider credentials() =>
      S3CredentialsProvider.static(accessKeyId: config.accessKeyId, secretAccessKey: config.secretKey);

  /// Answers each request with [handler] after recording it in [seen].
  http.Client recordingClient(void Function(http.BaseRequest request) seen, http.StreamedResponse Function() handler) =>
      _FakeHttpClient((request) async {
        seen(request);
        return handler();
      });

  S3ClientStorageService awsService({required http.Client httpClient, int maxUploadBytes = 1 << 30}) =>
      S3ClientStorageService(
        config: config,
        maxUploadBytes: maxUploadBytes,
        client: S3Client.aws(region: config.region, credentials: credentials(), httpClient: httpClient),
      );

  http.StreamedResponse okResponse() => http.StreamedResponse(const Stream.empty(), 200, headers: {'etag': '"abc"'});

  http.StreamedResponse xmlError(int status, String code) => http.StreamedResponse(
    Stream.value(utf8.encode('<Error><Code>$code</Code><Message>redacted</Message></Error>')),
    status,
  );

  group('request shape', () {
    test('sends one signed PUT to the virtual-hosted object URL, unsigned payload', () async {
      http.BaseRequest? seen;
      final service = awsService(httpClient: recordingClient((request) => seen = request, okResponse));

      await service.uploadObject(objectKey: 'guest/photo.jpg', data: Uint8List.fromList([1, 2, 3]));

      expect(seen, isNotNull);
      expect(seen!.method, 'PUT');
      expect(seen!.url.toString(), 'https://wedding-20261025.s3.eu-central-1.amazonaws.com/guest/photo.jpg');
      expect(seen!.headers['x-amz-content-sha256'], 'UNSIGNED-PAYLOAD');
      final auth = seen!.headers['authorization']!;
      expect(auth, startsWith('AWS4-HMAC-SHA256 Credential=AKIAIOSFODNN7EXAMPLE/'));
      expect(auth, contains('/eu-central-1/s3/aws4_request'));
    });

    test('uses path style for custom endpoints', () async {
      http.BaseRequest? seen;
      final service = S3ClientStorageService(
        config: const EventConfig(
          accessKeyId: 'AKIAIOSFODNN7EXAMPLE',
          secretKey: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
          bucket: 'wedding-20261025',
          region: 'eu-central-1',
          endpoint: 'storage.example.com',
        ),
        client: S3Client(
          baseEndpoint: Uri.parse('https://storage.example.com'),
          region: 'eu-central-1',
          credentials: credentials(),
          usePathStyle: true,
          httpClient: recordingClient((request) => seen = request, okResponse),
        ),
      );

      await service.uploadObject(objectKey: 'photo.jpg', data: Uint8List(0));

      expect(seen!.url.toString(), 'https://storage.example.com/wedding-20261025/photo.jpg');
    });

    test('reports coarse start/end progress', () async {
      final progress = <List<int>>[];
      final service = awsService(httpClient: recordingClient((_) {}, okResponse));

      await service.uploadObject(
        objectKey: 'a',
        data: Uint8List(5),
        onProgress: (sent, total) => progress.add([sent, total]),
      );

      expect(progress, [
        [0, 5],
        [5, 5],
      ]);
    });
  });

  group('error mapping', () {
    test('rejects oversized payloads client-side before any request', () async {
      var requests = 0;
      final service = awsService(maxUploadBytes: 4, httpClient: recordingClient((_) => requests++, okResponse));

      await expectLater(
        service.uploadObject(objectKey: 'a', data: Uint8List(5)),
        throwsA(
          isA<UploadException>()
              .having((e) => e.kind, 'kind', UploadErrorKind.payloadTooLarge)
              .having((e) => e.httpStatus, 'httpStatus', isNull),
        ),
      );
      expect(requests, 0);
    });

    test('maps 403 XML errors to clientError with provider code', () async {
      final service = awsService(httpClient: recordingClient((_) {}, () => xmlError(403, 'AccessDenied')));

      await expectLater(
        service.uploadObject(objectKey: 'a', data: Uint8List(1)),
        throwsA(
          isA<UploadException>()
              .having((e) => e.kind, 'kind', UploadErrorKind.clientError)
              .having((e) => e.providerErrorCode, 'providerErrorCode', 'AccessDenied'),
        ),
      );
    });

    test('maps EntityTooLarge to payloadTooLarge', () async {
      final service = awsService(httpClient: recordingClient((_) {}, () => xmlError(400, 'EntityTooLarge')));

      await expectLater(
        service.uploadObject(objectKey: 'a', data: Uint8List(1)),
        throwsA(isA<UploadException>().having((e) => e.kind, 'kind', UploadErrorKind.payloadTooLarge)),
      );
    });

    test('maps InternalError to serverError', () async {
      final service = awsService(httpClient: recordingClient((_) {}, () => xmlError(500, 'InternalError')));

      await expectLater(
        service.uploadObject(objectKey: 'a', data: Uint8List(1)),
        throwsA(
          isA<UploadException>()
              .having((e) => e.kind, 'kind', UploadErrorKind.serverError)
              .having((e) => e.providerErrorCode, 'providerErrorCode', 'InternalError'),
        ),
      );
    });

    test('maps non-XML error bodies via their numeric status fallback', () async {
      final service = awsService(
        httpClient: recordingClient((_) {}, () => http.StreamedResponse(Stream.value(utf8.encode('nope')), 503)),
      );

      await expectLater(
        service.uploadObject(objectKey: 'a', data: Uint8List(1)),
        throwsA(
          isA<UploadException>()
              .having((e) => e.kind, 'kind', UploadErrorKind.serverError)
              .having((e) => e.httpStatus, 'httpStatus', 503),
        ),
      );
    });

    test('maps transport failures to networkOrCors', () async {
      final service = awsService(
        httpClient: recordingClient(
          (_) {},
          () => throw http.ClientException('failed', Uri.parse('https://example.com')),
        ),
      );

      await expectLater(
        service.uploadObject(objectKey: 'a', data: Uint8List(1)),
        throwsA(isA<UploadException>().having((e) => e.kind, 'kind', UploadErrorKind.networkOrCors)),
      );
    });

    test('never leaks credential material from provider messages', () async {
      final service = awsService(
        httpClient: recordingClient(
          (_) {},
          // S3's InvalidAccessKeyId message echoes the access key ID.
          () => http.StreamedResponse(
            Stream.value(
              utf8.encode(
                '<Error><Code>InvalidAccessKeyId</Code>'
                '<Message>The AWS access key Id you provided does not exist '
                'in our records: ${config.accessKeyId}</Message></Error>',
              ),
            ),
            403,
          ),
        ),
      );

      Object? caught;
      try {
        await service.uploadObject(objectKey: 'a', data: Uint8List(1));
      } catch (e) {
        caught = e;
      }
      expect(caught, isA<UploadException>());
      expect(caught.toString(), isNot(contains(config.accessKeyId)));
      expect(caught.toString(), isNot(contains(config.secretKey)));
    });
  });
}

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient(this._handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest request) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Real clients (IOClient, BrowserClient) consume the request body
    // stream; s3_client blocks in `sink.addStream` while it is
    // unconsumed, so the fake must drain it too.
    await request.finalize().toBytes();
    return _handler(request);
  }
}
