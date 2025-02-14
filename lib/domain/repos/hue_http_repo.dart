import 'dart:io';

import 'package:dart_hue/domain/models/resource_type.dart';
import 'package:dart_hue/domain/services/hue_http_client.dart';
import 'package:dart_hue/exceptions/expired_token_exception.dart';
import 'package:dart_hue/utils/misc_tools.dart';

/// This is the way to communicate with Dart Hue HTTP services.
class HueHttpRepo {
  /// The device type for the bridge whitelist.
  static String get deviceType {
    /// Used as the suffix of this device's name in the bridge whitelist.
    String device;
    if (MiscTools.isWeb) {
      device = 'web';
    } else {
      switch (Platform.operatingSystem) {
        case 'android':
        case 'fuchsia':
        case 'linux':
          device = Platform.operatingSystem;
          break;
        case 'ios':
          device = 'iPhone';
          break;
        case 'macos':
          device = 'mac';
          break;
        case 'windows':
          device = 'pc';
          break;
        default:
          device = 'device';
      }
    }

    return 'FlutterHue#$device';
  }

  /// Returns a properly formatted target URL.
  ///
  /// `bridgeIpAddr` is the IP address of the target bridge.
  ///
  /// The `resourceType` is used to let the bridge know what type of resource is
  /// being queried.
  ///
  /// If a specific resource is being queried, include `pathToResource`. This is
  /// most likely the resource's ID.
  ///
  /// If `isRemote` is `true`, the URL will be formatted for remote access.
  static String getTargetUrl({
    required String bridgeIpAddr,
    ResourceType? resourceType,
    String? pathToResource,
    bool isRemote = false,
  }) {
    String domain = isRemote ? 'api.meethue.com/route' : bridgeIpAddr;

    String resourceTypeStr = resourceType?.value ?? '';

    if (resourceTypeStr.isNotEmpty) {
      resourceTypeStr = '/$resourceTypeStr';
    }

    String subPath = pathToResource ?? '';

    if (subPath.isNotEmpty && !subPath.startsWith('/')) {
      subPath = '/$subPath';
    }

    return 'https://$domain/clip/v2/resource$resourceTypeStr$subPath';
  }

  /// Fetch an existing resource.
  ///
  /// `bridgeIpAddr` is the IP address of the target bridge.
  ///
  /// If a specific resource is being queried, include `pathToResource`. This is
  /// most likely the resource's ID.
  ///
  /// `applicationKey` is the key associated with this devices in the bridge's
  /// whitelist.
  ///
  /// The `resourceType` is used to let the bridge know what type of resource is
  /// being queried.
  ///
  /// `token` is the access token for remote access.
  ///
  /// May throw [ExpiredAccessTokenException] if trying to connect to the bridge
  /// remotely and the token is expired. If this happens, refresh the token with
  /// [TokenRepo.refreshRemoteToken].
  static Future<Map<String, dynamic>?> get({
    required String bridgeIpAddr,
    String? pathToResource,
    required String applicationKey,
    required ResourceType? resourceType,
    required String? token,
  }) async {
    return await HueHttpClient.get(
      url: getTargetUrl(
        bridgeIpAddr: bridgeIpAddr,
        resourceType: resourceType,
        pathToResource: pathToResource,
        isRemote: false,
      ),
      applicationKey: applicationKey,
      token: null,
    ).timeout(
      const Duration(seconds: 1),
      onTimeout: () async {
        return await HueHttpClient.get(
          url: getTargetUrl(
            bridgeIpAddr: bridgeIpAddr,
            resourceType: resourceType,
            pathToResource: pathToResource,
            isRemote: true,
          ),
          applicationKey: applicationKey,
          token: token,
        );
      },
    );
  }

  /// Create a new resource.
  ///
  /// `bridgeIpAddr` is the IP address of the target bridge.
  ///
  /// If a specific resource is being queried, include `pathToResource`. This is
  /// most likely the resource's ID.
  ///
  /// `applicationKey` is the key associated with this devices in the bridge's
  /// whitelist.
  ///
  /// The `resourceType` is used to let the bridge know what type of resource is
  /// being queried.
  ///
  /// `body` is the actual content being sent to the bridge.
  ///
  /// `token` is the access token for remote access.
  ///
  /// May throw [ExpiredAccessTokenException] if trying to connect to the bridge
  /// remotely and the token is expired. If this happens, refresh the token with
  /// [TokenRepo.refreshRemoteToken].
  static Future<Map<String, dynamic>?> post({
    required String bridgeIpAddr,
    String? pathToResource,
    required String applicationKey,
    required ResourceType? resourceType,
    required String body,
    required String? token,
  }) async {
    return await HueHttpClient.post(
      url: getTargetUrl(
        bridgeIpAddr: bridgeIpAddr,
        resourceType: resourceType,
        pathToResource: pathToResource,
        isRemote: false,
      ),
      applicationKey: applicationKey,
      token: null,
      body: body,
    ).timeout(
      const Duration(seconds: 1),
      onTimeout: () async {
        return await HueHttpClient.post(
          url: getTargetUrl(
            bridgeIpAddr: bridgeIpAddr,
            resourceType: resourceType,
            pathToResource: pathToResource,
            isRemote: true,
          ),
          applicationKey: applicationKey,
          token: token,
          body: body,
        );
      },
    );
  }

  /// Update an existing resource.
  ///
  /// `bridgeIpAddr` is the IP address of the target bridge.
  ///
  /// If a specific resource is being queried, include `pathToResource`. This is
  /// most likely the resource's ID.
  ///
  /// `applicationKey` is the key associated with this devices in the bridge's
  /// whitelist.
  ///
  /// The `resourceType` is used to let the bridge know what type of resource is
  /// being queried.
  ///
  /// `body` is the actual content being sent to the bridge.
  ///
  /// `token` is the access token for remote access.
  ///
  /// May throw [ExpiredAccessTokenException] if trying to connect to the bridge
  /// remotely and the token is expired. If this happens, refresh the token with
  /// [TokenRepo.refreshRemoteToken].
  static Future<Map<String, dynamic>?> put({
    required String bridgeIpAddr,
    String? pathToResource,
    required String applicationKey,
    required ResourceType? resourceType,
    required String body,
    required String? token,
  }) async {
    return await HueHttpClient.put(
      url: getTargetUrl(
        bridgeIpAddr: bridgeIpAddr,
        resourceType: resourceType,
        pathToResource: pathToResource,
        isRemote: false,
      ),
      applicationKey: applicationKey,
      token: null,
      body: body,
    ).timeout(
      const Duration(seconds: 1),
      onTimeout: () async {
        return await HueHttpClient.put(
          url: getTargetUrl(
            bridgeIpAddr: bridgeIpAddr,
            resourceType: resourceType,
            pathToResource: pathToResource,
            isRemote: true,
          ),
          applicationKey: applicationKey,
          token: token,
          body: body,
        );
      },
    );
  }

  /// Delete an existing resource.
  ///
  /// `bridgeIpAddr` is the IP address of the target bridge.
  ///
  /// If a specific resource is being queried, include `pathToResource`. This is
  /// most likely the resource's ID.
  ///
  /// `applicationKey` is the key associated with this devices in the bridge's
  /// whitelist.
  ///
  /// The `resourceType` is used to let the bridge know what type of resource is
  /// being queried.
  ///
  /// `token` is the access token for remote access.
  ///
  /// May throw [ExpiredAccessTokenException] if trying to connect to the bridge
  /// remotely and the token is expired. If this happens, refresh the token with
  /// [TokenRepo.refreshRemoteToken].
  static Future<Map<String, dynamic>?> delete({
    required String bridgeIpAddr,
    required String pathToResource,
    required String applicationKey,
    required ResourceType? resourceType,
    required String? token,
  }) async {
    return await HueHttpClient.delete(
      url: getTargetUrl(
        bridgeIpAddr: bridgeIpAddr,
        resourceType: resourceType,
        pathToResource: pathToResource,
        isRemote: false,
      ),
      applicationKey: applicationKey,
      token: null,
    ).timeout(
      const Duration(seconds: 1),
      onTimeout: () async {
        return await HueHttpClient.delete(
          url: getTargetUrl(
            bridgeIpAddr: bridgeIpAddr,
            resourceType: resourceType,
            pathToResource: pathToResource,
            isRemote: true,
          ),
          applicationKey: applicationKey,
          token: token,
        );
      },
    );
  }
}
