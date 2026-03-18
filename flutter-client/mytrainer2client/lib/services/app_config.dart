import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

const bool _useLanDevHost =
    bool.fromEnvironment('USE_LAN_DEV_HOST', defaultValue: false);
const String _lanDevHost =
    String.fromEnvironment('DEV_LAN_HOST', defaultValue: '192.168.0.127');
const String _apiBaseUrlOverride =
    String.fromEnvironment('API_BASE_URL', defaultValue: '');
const String _keycloakRealmUrlOverride =
    String.fromEnvironment('KEYCLOAK_REALM_URL', defaultValue: '');
const String _keycloakLogoutUrlOverride =
    String.fromEnvironment('KEYCLOAK_LOGOUT_URL', defaultValue: '');

String get _defaultDevHost {
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

class AppConfig {
  static const appTitle =
      String.fromEnvironment('APP_TITLE', defaultValue: 'MVFitness');
  static const oidcClientId =
      String.fromEnvironment('OIDC_CLIENT_ID', defaultValue: 'mytrainer2client');
  static const appUriScheme =
      String.fromEnvironment('APP_URI_SCHEME', defaultValue: 'mytrainer');
  static const androidAppPackage = String.fromEnvironment(
    'ANDROID_APP_PACKAGE',
    defaultValue: 'com.mvfitness.mytrainer2client',
  );
  static const mobileRedirectUri = String.fromEnvironment(
    'MOBILE_REDIRECT_URI',
    defaultValue: 'com.mvfitness.mytrainer2client://oauthredirect',
  );
  static const mobilePostLogoutRedirectUri = String.fromEnvironment(
    'MOBILE_POST_LOGOUT_REDIRECT_URI',
    defaultValue: 'com.mvfitness.mytrainer2client://logoutredirect',
  );

  static final apiBaseUrl = _apiBaseUrlOverride.isNotEmpty
      ? _apiBaseUrlOverride
      : 'http://$_defaultDevHost:8080';

  static final keycloakRealmUrl = _keycloakRealmUrlOverride.isNotEmpty
      ? _keycloakRealmUrlOverride
      : 'http://$_defaultDevHost:8081/realms/myrealm';

  static final keycloakLogoutUrl = _keycloakLogoutUrlOverride.isNotEmpty
      ? _keycloakLogoutUrlOverride
      : '$keycloakRealmUrl/protocol/openid-connect/logout';

  static final allowInsecureConnections =
      const bool.fromEnvironment('ALLOW_INSECURE_AUTH', defaultValue: false) ||
          keycloakRealmUrl.startsWith('http://');
}
