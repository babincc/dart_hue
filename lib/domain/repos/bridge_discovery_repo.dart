import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dart_hue/constants/api_fields.dart';
import 'package:dart_hue/domain/models/bridge/bridge.dart';
import 'package:dart_hue/domain/models/bridge/discovered_bridge.dart';
import 'package:dart_hue/domain/models/resource_type.dart';
import 'package:dart_hue/domain/repos/hue_http_repo.dart';
import 'package:dart_hue/domain/services/bridge_discovery_service.dart';
import 'package:dart_hue/domain/services/hue_http_client.dart';
import 'package:dart_hue/utils/json_tool.dart';
import 'package:dart_hue/utils/misc_tools.dart';

/// This is the way to communicate with Dart Hue Bridge services.
class BridgeDiscoveryRepo {
  /// Searches the network for Philips Hue bridges.
  ///
  /// Returns a list of [DiscoveredBridge] objects. These contain the IP address
  /// of the bridge and a partial ID of the bridge.
  ///
  /// If `savedBridges` is provided, the bridges that are already saved to the
  /// device will be removed from the search results.
  static Future<List<DiscoveredBridge>> discoverBridges({
    List<Bridge> savedBridges = const [],
  }) async {
    /// Bridges found using MDNS.
    List<DiscoveredBridge> bridgesFromMdns;
    if (MiscTools.isWeb) {
      // mDNS does not work on web.
      bridgesFromMdns = [];
    } else {
      bridgesFromMdns = await BridgeDiscoveryService.discoverBridgesMdns();
    }

    /// Bridges found using the endpoint method.
    List<DiscoveredBridge> bridgesFromEndpoint =
        await BridgeDiscoveryService.discoverBridgesEndpoint();

    // Remove duplicates from the two search methods.
    Set<DiscoveredBridge> uniqueValues = {};
    for (final DiscoveredBridge bridgeFromMdns in bridgesFromMdns) {
      for (final DiscoveredBridge bridgeFromEndpoint in bridgesFromEndpoint) {
        if (bridgeFromMdns.ipAddress == bridgeFromEndpoint.ipAddress) {
          bridgeFromMdns.rawIdFromEndpoint =
              bridgeFromEndpoint.rawIdFromEndpoint;
          bridgesFromEndpoint.remove(bridgeFromEndpoint);
          break;
        }
      }
      uniqueValues.add(bridgeFromMdns);
    }
    uniqueValues.addAll(bridgesFromEndpoint);

    if (savedBridges.isEmpty) return uniqueValues.toList();

    List<DiscoveredBridge> newBridges = [];

    // Remove the bridges that are already saved to the device from the search
    // results.
    for (final DiscoveredBridge discoveredBridge in uniqueValues) {
      bool isSaved = false;

      for (Bridge bridge in savedBridges) {
        if (bridge.ipAddress != null &&
            bridge.ipAddress == discoveredBridge.ipAddress) {
          isSaved = true;
          break;
        }
      }

      if (!isSaved) {
        newBridges.add(discoveredBridge);
      }
    }

    return newBridges;
  }

  /// Initiates the first contact between this device and the given bridge.
  ///
  /// Once this method has been called, the user will have 10 seconds by
  /// default, or how ever many have been set in `controller`, to press the
  /// button on their bridge to confirm they have physical access to it.
  ///
  /// In the event of a successful pairing, this method returns a bridge object
  /// that represents the bridge it just connected to.
  ///
  /// `controller` gives more control over this process. It lets you decide how
  /// many seconds the user has to press the button on their bridge. It also
  /// gives the ability to cancel the discovery process at any time.
  ///
  /// If the pairing fails, this method returns `null`.
  static Future<Bridge?> firstContact({
    required String bridgeIpAddr,
    DiscoveryTimeoutController? controller,
  }) async {
    final DiscoveryTimeoutController timeoutController =
        controller ?? DiscoveryTimeoutController();

    Map<String, dynamic>? response;

    String? appKey;

    String? clientKey;

    final String body = JsonTool.writeJson(
      {
        ApiFields.deviceType: HueHttpRepo.deviceType,
        ApiFields.generateClientKey: true,
      },
    );

    // Try for [timeoutSeconds] to connect with the bridge.
    int counter = 0;
    await Future.doWhile(
      () => Future.delayed(const Duration(seconds: 1)).then(
        (value) async {
          counter++;

          // Timeout after [timeoutSeconds].
          if (counter > timeoutController.timeoutSeconds) return false;

          // Cancel if called to do so, early.
          if (timeoutController.cancelDiscovery) {
            timeoutController.cancelDiscovery = false;
            return false;
          }

          response = await HueHttpClient.post(
            url: 'https://$bridgeIpAddr/api',
            applicationKey: null,
            token: null,
            body: body,
          );

          if (response == null || response!.isEmpty) return true;

          try {
            if (response!.containsKey(ApiFields.error)) {
              return response![ApiFields.error][ApiFields.description] ==
                  'link button not pressed';
            } else {
              appKey = response![ApiFields.success][ApiFields.username];
              clientKey = response![ApiFields.success][ApiFields.clientKey];
              return appKey == null || appKey!.isEmpty;
            }
          } catch (_) {
            return true;
          }
        },
      ),
    );

    if (appKey == null) return null;

    // Upon successful connection, get the bridge details.
    Map<String, dynamic>? bridgeJson = await HueHttpRepo.get(
      bridgeIpAddr: bridgeIpAddr,
      applicationKey: appKey!,
      resourceType: ResourceType.bridge,
      token: null,
    );

    if (bridgeJson == null) return null;

    final Bridge bridge = Bridge.fromJson(bridgeJson).copyWith(
      ipAddress: bridgeIpAddr,
      applicationKey: appKey,
      clientKey: clientKey,
    );

    if (bridge.id.isEmpty) return null;

    return bridge;
  }

  /// This method allows the user to grant access to the app to allow it to
  /// connect to their bridge.
  ///
  /// This is step 1. Step 2 is [TokenRepo.fetchRemoteToken].
  ///
  /// `clientId` Identifies the client that is making the request. The value
  /// passed in this parameter must exactly match the value you receive from
  /// hue.
  ///
  /// `redirectUri` This parameter must exactly match the one configured in your
  /// hue developer account.
  ///
  /// `deviceName` The device name should be the name of the app or device
  /// accessing the remote API. The `deviceName` is used in the user’s “My Apps”
  /// overview in the Hue Account (visualized as: “[appName] on [deviceName]”).
  ///
  /// `state` Provides any state that might be useful to your application upon
  /// receipt of the response. The Hue Authorization Server round-trips this
  /// parameter, so your application receives the same value it sent. To
  /// mitigate against cross-site request forgery (CSRF), a long (30+ digit),
  /// random number is prepended to `state`. When the response is received from
  /// Hue, it is recommended that you compare the string returned from this
  /// method, to the one that is returned from Hue.
  ///
  /// Returns a map with the key `url` and `state`. The `url` is the URL that
  /// the user needs to visit to grant access to the app. The `state` value is
  /// what is sent with the GET request. This is prepended with the long, random
  /// number. Between the random number and the provided `state` will be a -
  /// (dash).
  static Future<Map<String, String>> remoteAuthRequest({
    required String clientId,
    required String redirectUri,
    String? deviceName,
    String? state,
  }) async {
    final StringBuffer urlBuffer =
        StringBuffer('https://api.meethue.com/v2/oauth2/authorize?');
    final StringBuffer stateBuffer = StringBuffer();

    // Generate a random code verifier.
    final String codeVerifier = base64Url
        .encode(List.generate(32, (index) => MiscTools.randInt(0, 255)));

    // Calculate the code challenge using SHA-256.
    final String codeChallenge =
        base64Url.encode(sha256.convert(utf8.encode(codeVerifier)).bytes);

    // Write the URI.
    urlBuffer.write('${ApiFields.clientId}=$clientId');
    urlBuffer.write('&${ApiFields.responseType}=code');
    urlBuffer.write('&${ApiFields.codeChallengeMethod}=S256');
    urlBuffer.write('&${ApiFields.codeChallenge}=$codeChallenge');
    urlBuffer.write('&${ApiFields.state}=');
    stateBuffer.write(MiscTools.randInt(1, 123).toString());
    for (int i = 0; i < MiscTools.randInt(30, 44); i++) {
      stateBuffer.write(MiscTools.randInt(0, 123).toString());
    }
    urlBuffer.write(stateBuffer.toString());
    if (state != null && state.isNotEmpty) {
      urlBuffer.write('-$state');
    }
    urlBuffer.write('&${ApiFields.redirectUri}=$redirectUri');
    if (deviceName != null && deviceName.isNotEmpty) {
      urlBuffer.write('&${ApiFields.deviceName}=$deviceName');
    }

    return {'url': urlBuffer.toString(), 'state': stateBuffer.toString()};
  }
}

/// Gives more control over the bridge discovery process.
class DiscoveryTimeoutController {
  /// Creates a [DiscoveryTimeoutController].
  ///
  /// Range for `timeoutSeconds` is 0 to 30 (inclusive).
  DiscoveryTimeoutController({
    this.timeoutSeconds = 10,
  }) : assert(timeoutSeconds >= 0 && timeoutSeconds <= 30,
            '`timeoutSeconds` must be between 0 and 30 (inclusive)');

  /// How many seconds the user has to press the button on their bridge before
  /// the process times out.
  int timeoutSeconds;

  /// `true` if the bridge discovery process needs to be canceled.
  bool cancelDiscovery = false;
}
