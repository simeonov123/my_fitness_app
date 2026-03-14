import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

const bool _useLanDevHost =
    bool.fromEnvironment('USE_LAN_DEV_HOST', defaultValue: false);
const String _lanDevHost =
    String.fromEnvironment('DEV_LAN_HOST', defaultValue: '192.168.0.127');

String get _devHost {
  if (kIsWeb) {
    return 'localhost';
  }
  if (_useLanDevHost) {
    return _lanDevHost;
  }
  if (Platform.isAndroid) {
    return '10.0.2.2';
  }
  return 'localhost';
}

String get apiBaseUrl => 'http://$_devHost:8080';

String get keycloakRealmUrl => 'http://$_devHost:8081/realms/myrealm';

String get keycloakLogoutUrl =>
    '$keycloakRealmUrl/protocol/openid-connect/logout';
