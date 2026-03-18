# Release Setup

This app now supports runtime configuration through `--dart-define` values.

## Local Development

If you do nothing, the app keeps the current local-development behavior:

- Web uses `http://localhost:8080`
- iOS uses `http://localhost:8080`
- Android emulator uses `http://10.0.2.2:8080`
- Keycloak defaults to the same host on port `8081`

Optional local overrides:

```bash
flutter run \
  --dart-define=USE_LAN_DEV_HOST=true \
  --dart-define=DEV_LAN_HOST=192.168.0.127
```

Or explicitly set full endpoints:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://192.168.0.127:8080 \
  --dart-define=KEYCLOAK_REALM_URL=http://192.168.0.127:8081/realms/myrealm \
  --dart-define=ALLOW_INSECURE_AUTH=true
```

## Release

For release builds, set production values explicitly:

```bash
flutter build web --release \
  --dart-define=APP_TITLE=MVFitness \
  --dart-define=API_BASE_URL=https://api.example.com \
  --dart-define=KEYCLOAK_REALM_URL=https://auth.example.com/realms/myrealm \
  --dart-define=KEYCLOAK_LOGOUT_URL=https://auth.example.com/realms/myrealm/protocol/openid-connect/logout \
  --dart-define=OIDC_CLIENT_ID=mytrainer2client \
  --dart-define=ALLOW_INSECURE_AUTH=false
```

Mobile release example:

```bash
flutter build ios --release \
  --dart-define=API_BASE_URL=https://api.example.com \
  --dart-define=KEYCLOAK_REALM_URL=https://auth.example.com/realms/myrealm \
  --dart-define=KEYCLOAK_LOGOUT_URL=https://auth.example.com/realms/myrealm/protocol/openid-connect/logout \
  --dart-define=OIDC_CLIENT_ID=mytrainer2client \
  --dart-define=MOBILE_REDIRECT_URI=com.mvfitness.mytrainer2client://oauthredirect \
  --dart-define=MOBILE_POST_LOGOUT_REDIRECT_URI=com.mvfitness.mytrainer2client://logoutredirect \
  --dart-define=APP_URI_SCHEME=mytrainer \
  --dart-define=ANDROID_APP_PACKAGE=com.mvfitness.mytrainer2client \
  --dart-define=ALLOW_INSECURE_AUTH=false
```

## Values You Should Review Before Release

- `API_BASE_URL`
- `KEYCLOAK_REALM_URL`
- `KEYCLOAK_LOGOUT_URL`
- `OIDC_CLIENT_ID`
- `MOBILE_REDIRECT_URI`
- `MOBILE_POST_LOGOUT_REDIRECT_URI`
- `APP_URI_SCHEME`
- `ANDROID_APP_PACKAGE`
- `APP_TITLE`

## Functional Release Notes

- Programs and Nutrition tabs are intentionally marked as `Coming soon`
- Social cards can be exported as PNGs from the Social tab
- Auth and API endpoints now read from runtime config instead of fixed local URLs
