import 'dart:io';

/// The Dart Hue folder structure.
class Folders {
  /// The top level folder.
  static const top = 'dart_hue';

  /// The folder for the bridges.
  static const bridges = 'bridges';

  /// The folder for the remote tokens.
  static const remoteTokens = 'rt';

  /// The sub path for the bridges.
  static String get bridgesSubPath =>
      '$top${Platform.pathSeparator}$bridges${Platform.pathSeparator}';

  /// The sub path for the remote tokens.
  static String get remoteTokensSubPath =>
      '$top${Platform.pathSeparator}$remoteTokens${Platform.pathSeparator}';
}
