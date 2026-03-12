import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PendingClientInviteService {
  PendingClientInviteService._internal();
  static final PendingClientInviteService _instance =
      PendingClientInviteService._internal();
  factory PendingClientInviteService() => _instance;

  static const _key = 'pending_client_invite_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) => _storage.write(key: _key, value: token);

  Future<String?> readToken() => _storage.read(key: _key);

  Future<void> clear() => _storage.delete(key: _key);
}
