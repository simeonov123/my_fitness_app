// lib/providers/api_provider.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// A [ChangeNotifier] that exposes a simple way to call a secure API
/// endpoint and holds the result in [data].
///
/// Consumers can watch [data] to react to fresh API responses.
class ApiProvider extends ChangeNotifier {
  /// Underlying service that handles token management and HTTP calls.
  final ApiService _api = ApiService();

  /// The most recent API response body, or `null` if none fetched yet.
  String? data;

  /// Calls the secure endpoint at [path], storing the response in [data].
  ///
  /// Internally this:
  ///  1. Asks [ApiService] for a valid access token (refreshing if needed).
  ///  2. Performs an HTTP GET to `$_baseUrl$path`.
  ///  3. Sets [data] to the response body on HTTP 200, or to `'Error loading'` otherwise.
  ///  4. Calls [notifyListeners] so UI can rebuild.
  Future<void> loadData() async {
    data = await _api.fetchSecure('/trainer/dashboard') ?? 'Error loading';
    notifyListeners();
  }
}
