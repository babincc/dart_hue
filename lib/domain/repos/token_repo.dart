import 'package:dart_hue/constants/api_fields.dart';
import 'package:dart_hue/domain/repos/bridge_discovery_repo.dart';
import 'package:dart_hue/domain/services/token_service.dart';
import 'package:dart_hue/exceptions/expired_token_exception.dart';
import 'package:dart_hue/utils/date_time_tool.dart';

class TokenRepo {
  /// This method fetches the token that grants temporary access to the bridge.
  ///
  /// This is step 2. Step 1 is [BridgeDiscoveryRepo.remoteAuthRequest].
  ///
  /// `clientId` Identifies the client that is making the request. The value
  /// passed in this parameter must exactly match the value you receive from
  /// hue.
  ///
  /// `clientSecret` The client secret you have received from Hue when
  /// registering for the Hue Remote API.
  ///
  /// `pkce` The code verifier that was generated in
  /// [BridgeDiscoveryRepo.remoteAuthRequest]. This is returned and captured
  /// from the deep link.
  ///
  /// `code` The code that was returned from the deep link. This is what is
  /// being traded for the token.
  ///
  /// `stateSecret` The state secret that was generated in
  /// [BridgeDiscoveryRepo.remoteAuthRequest]. This method can either take the
  /// full state value, or just the secret part.
  ///
  /// Returns a map with the token, expiration date, refresh token, and token
  /// type. If the token is not found, returns `null`.
  static Future<Map<String, dynamic>?> fetchRemoteToken({
    required String clientId,
    required String clientSecret,
    required String pkce,
    required String code,
  }) async {
    // Call the service.
    Map<String, dynamic>? res = await TokenService.fetchRemoteToken(
      clientId: clientId,
      clientSecret: clientSecret,
      pkce: pkce,
      code: code,
    );

    if (res == null) return null;

    return _formatRemoteTokenData(res);
  }

  /// This method fetches the token that grants temporary access to the bridge.
  ///
  /// This is step 2. Step 1 is [BridgeDiscoveryRepo.remoteAuthRequest].
  ///
  /// `clientId` Identifies the client that is making the request. The value
  /// passed in this parameter must exactly match the value you receive from
  /// hue.
  ///
  /// `clientSecret` The client secret you have received from Hue when
  /// registering for the Hue Remote API.
  ///
  /// `oldRemoteToken` The old token that is being refreshed.
  ///
  /// May throw [ExpiredRefreshTokenException] if the remote token is expired.
  /// If this happens, get the user to grand access to the app again by using
  /// [BridgeDiscoveryRepo.remoteAuthRequest].
  static Future<Map<String, dynamic>?> refreshRemoteToken({
    required String clientId,
    required String clientSecret,
    required String oldRemoteToken,
  }) async {
    // Call the service.
    Map<String, dynamic>? res = await TokenService.refreshRemoteToken(
      clientId: clientId,
      clientSecret: clientSecret,
      refreshToken: oldRemoteToken,
    );

    if (res == null) return null;

    return _formatRemoteTokenData(res);
  }

  /// This method writes the remote tokens to local storage.
  static Map<String, dynamic>? _formatRemoteTokenData(
    Map<String, dynamic> res,
  ) {
    String? accessToken = res[ApiFields.accessToken];
    int? expiresIn = res[ApiFields.expiresIn];
    String? refreshToken = res[ApiFields.refreshToken];
    String? tokenType = res[ApiFields.tokenType];

    if (accessToken == null ||
        expiresIn == null ||
        refreshToken == null ||
        tokenType == null) {
      return null;
    }

    // Calculate the expiration date.
    DateTime expirationDate = DateTime.now().add(
      Duration(seconds: expiresIn),
    );

    // Add the expiration date to the map.
    res[ApiFields.expirationDate] = DateTimeTool.toHueString(expirationDate);

    // Write the tokens to local storage.
    return res;
  }
}
