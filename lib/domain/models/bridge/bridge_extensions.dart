import 'package:dart_hue/constants/api_fields.dart';
import 'package:dart_hue/domain/models/bridge/bridge.dart';
import 'package:dart_hue/domain/models/resource.dart';
import 'package:dart_hue/domain/models/resource_type.dart';
import 'package:dart_hue/domain/repos/hue_http_repo.dart';
import 'package:dart_hue/utils/json_tool.dart';
import 'package:dart_hue/utils/misc_tools.dart';

/// Hue HTTP repo requests made easy.
extension HttpRequests on Bridge {
  /// Fetch the given `resource` from this bridge.
  ///
  /// `token` is the access token for remote access.
  ///
  /// Will return `null` if:
  /// * The `resource` does not exist on this bridge
  /// * This bridge does not have an IP address
  /// * This bridge does not have an application key
  /// * Any other unforeseen error
  Future<Map<String, dynamic>?> get(
    Resource resource, {
    String? token,
  }) async {
    if (ipAddress == null) return null;
    if (applicationKey == null) return null;

    try {
      return await HueHttpRepo.get(
        bridgeIpAddr: ipAddress!,
        pathToResource: resource.id,
        applicationKey: applicationKey!,
        resourceType: resource.type,
        token: token,
      );
    } catch (_) {
      return null;
    }
  }

  /// Fetch all resources of the given resource `type` from this bridge.
  ///
  /// `token` is the access token for remote access.
  ///
  /// Will return `null` if:
  /// * This bridge does not have an IP address
  /// * This bridge does not have an application key
  /// * Any other unforeseen error
  Future<List<Map<String, dynamic>>?> getResource(
    ResourceType type, {
    String? token,
  }) async {
    if (ipAddress == null) return null;
    if (applicationKey == null) return null;

    try {
      final Map<String, dynamic>? result = await HueHttpRepo.get(
        bridgeIpAddr: ipAddress!,
        applicationKey: applicationKey!,
        resourceType: type,
        token: token,
      );

      if (result == null) return null;

      return MiscTools.extractDataList(result);
    } catch (_) {
      return null;
    }
  }

  /// Fetch the given `resource` from this bridge.
  ///
  /// `token` is the access token for remote access.
  ///
  /// If the POST request is successful, then the original values in `resource`
  /// will be refreshed and set to their current values. To disable this
  /// behavior, set `refreshOriginals` to `false`.
  ///
  /// Will return `null` if:
  /// * The `resource` does not exist on this bridge
  /// * This bridge does not have an IP address
  /// * This bridge does not have an application key
  /// * The `resource` does not have any data to POST
  /// * Any other unforeseen error
  Future<Map<String, dynamic>?> post(
    Resource resource, {
    String? token,
    bool refreshOriginals = true,
  }) async {
    if (ipAddress == null) return null;
    if (applicationKey == null) return null;

    final Map<String, dynamic> resourceJson =
        resource.toJson(optimizeFor: OptimizeFor.post);

    if (resourceJson.isEmpty) return null;

    String body = JsonTool.writeJson(resourceJson);

    try {
      Map<String, dynamic>? result = await HueHttpRepo.post(
        bridgeIpAddr: ipAddress!,
        pathToResource: resource.id,
        applicationKey: applicationKey!,
        resourceType: resource.type,
        body: body,
        token: token,
      );

      if (result == null) return null;

      if (result[ApiFields.errors] == null ||
          (result[ApiFields.errors] as List<dynamic>).isEmpty) {
        resource.refreshOriginals();
      }

      return result;
    } catch (_) {
      return null;
    }
  }

  /// Fetch the given `resource` from this bridge.
  ///
  /// `token` is the access token for remote access.
  ///
  /// If the PUT request is successful, then the original values in `resource`
  /// will be refreshed and set to their current values. To disable this
  /// behavior, set `refreshOriginals` to `false`.
  ///
  /// Will return `null` if:
  /// * The `resource` does not exist on this bridge
  /// * This bridge does not have an IP address
  /// * This bridge does not have an application key
  /// * The `resource` does not have any data to PUT
  /// * Any other unforeseen error
  Future<Map<String, dynamic>?> put(
    Resource resource, {
    String? token,
    bool refreshOriginals = true,
  }) async {
    if (ipAddress == null) return null;
    if (applicationKey == null) return null;

    final Map<String, dynamic> resourceJson =
        resource.toJson(optimizeFor: OptimizeFor.put);

    if (resourceJson.isEmpty) return null;

    String body = JsonTool.writeJson(resourceJson);

    try {
      Map<String, dynamic>? result = await HueHttpRepo.put(
        bridgeIpAddr: ipAddress!,
        pathToResource: resource.id,
        applicationKey: applicationKey!,
        resourceType: resource.type,
        body: body,
        token: token,
      );

      if (result == null) return null;

      if (result[ApiFields.errors] == null ||
          (result[ApiFields.errors] as List<dynamic>).isEmpty) {
        resource.refreshOriginals();
      }

      return result;
    } catch (_) {
      return null;
    }
  }

  /// Fetch the given `resource` from this bridge.
  ///
  /// `token` is the access token for remote access.
  ///
  /// Will return `null` if:
  /// * The `resource` does not exist on this bridge
  /// * This bridge does not have an IP address
  /// * This bridge does not have an application key
  /// * Any other unforeseen error
  Future<Map<String, dynamic>?> delete(
    Resource resource, {
    String? token,
  }) async {
    if (ipAddress == null) return null;
    if (applicationKey == null) return null;

    try {
      return await HueHttpRepo.delete(
        bridgeIpAddr: ipAddress!,
        pathToResource: resource.id,
        applicationKey: applicationKey!,
        resourceType: resource.type,
        token: token,
      );
    } catch (_) {
      return null;
    }
  }
}
