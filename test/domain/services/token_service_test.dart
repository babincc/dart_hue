import 'package:dart_hue/domain/services/token_service.dart';
import 'package:dart_hue/exceptions/expired_token_exception.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';

class _TrackingClient extends MockClient {
  _TrackingClient(super.handler);
  bool closed = false;
  @override
  void close() {
    closed = true;
    super.close();
  }
}

void main() {
  for (final status in [400, 401]) {
    test('refresh rejection $status throws and closes the client', () async {
      final client = _TrackingClient((request) async => Response('{}', status));
      await expectLater(
        runWithClient(
          () => TokenService.refreshRemoteToken(
              clientId: 'id', clientSecret: 'secret', refreshToken: 'refresh'),
          () => client,
        ),
        throwsA(isA<ExpiredRefreshTokenException>()),
      );
      expect(client.closed, isTrue);
    });
  }
  test('successful refresh returns token data and closes the client', () async {
    final client = _TrackingClient((request) async {
      expect(request.bodyFields['grant_type'], 'refresh_token');
      expect(request.bodyFields['refresh_token'], 'refresh');
      return Response('{"access_token":"token"}', 200);
    });
    final result = await runWithClient(
      () => TokenService.refreshRemoteToken(
          clientId: 'id', clientSecret: 'secret', refreshToken: 'refresh'),
      () => client,
    );
    expect(result, {'access_token': 'token'});
    expect(client.closed, isTrue);
  });
  test('server error does not imply an expired refresh token', () async {
    final client = _TrackingClient((request) async => Response('{}', 500));
    final result = await runWithClient(
      () => TokenService.refreshRemoteToken(
          clientId: 'id', clientSecret: 'secret', refreshToken: 'refresh'),
      () => client,
    );
    expect(result, isNull);
    expect(client.closed, isTrue);
  });
  test('failed initial authorization does not imply an expired refresh token',
      () async {
    final client = _TrackingClient((request) async => Response('{}', 400));
    final result = await runWithClient(
      () => TokenService.fetchRemoteToken(
          clientId: 'id', clientSecret: 'secret', pkce: 'pkce', code: 'code'),
      () => client,
    );
    expect(result, isNull);
    expect(client.closed, isTrue);
  });
  test('client closes when the request throws', () async {
    final client =
        _TrackingClient((request) async => throw ClientException('failed'));
    await expectLater(
      runWithClient(
        () => TokenService.refreshRemoteToken(
            clientId: 'id', clientSecret: 'secret', refreshToken: 'refresh'),
        () => client,
      ),
      throwsA(isA<ClientException>()),
    );
    expect(client.closed, isTrue);
  });
}
