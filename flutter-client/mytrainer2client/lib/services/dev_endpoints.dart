import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

String get _devHost {
  if (kIsWeb) {
    return 'localhost';
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
