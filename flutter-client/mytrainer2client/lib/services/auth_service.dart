// lib/services/auth_service.dart

/// Conditionally exports the platform‐appropriate AuthService:
///
///  • If neither `dart:html` nor `dart:io` is available, uses `auth_service_stub.dart`
///  • If web, uses `auth_service_web.dart`
///  • If mobile (Android/iOS), uses `auth_service_mobile.dart`
library;

export 'auth_service_stub.dart'
    if (dart.library.html) 'auth_service_web.dart'
    if (dart.library.io) 'auth_service_mobile.dart';
