class ClientInvite {
  final int id;
  final int clientId;
  final String clientName;
  final String? clientEmail;
  final String status;
  final String inviteToken;
  final String inviteUrl;
  final String webInviteUrl;
  final DateTime? expiresAt;
  final DateTime? acceptedAt;
  final DateTime? createdAt;

  const ClientInvite({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.status,
    required this.inviteToken,
    required this.inviteUrl,
    required this.webInviteUrl,
    required this.expiresAt,
    required this.acceptedAt,
    required this.createdAt,
  });

  bool get isPending => status == 'PENDING';
  bool get isAccepted => status == 'ACCEPTED';

  String get iosInviteUrl => inviteUrl;
  String get androidInviteUrl =>
      'intent://invite/client?token=$inviteToken#Intent;scheme=mytrainer;package=com.mvfitness.mytrainer2client;end';

  factory ClientInvite.fromJson(Map<String, dynamic> json) => ClientInvite(
        id: (json['id'] ?? 0) as int,
        clientId: (json['clientId'] ?? 0) as int,
        clientName: (json['clientName'] ?? '') as String,
        clientEmail: json['clientEmail'] as String?,
        status: (json['status'] ?? '') as String,
        inviteToken: (json['inviteToken'] ?? '') as String,
        inviteUrl: (json['inviteUrl'] ?? '') as String,
        webInviteUrl: (json['webInviteUrl'] ?? '') as String,
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : null,
        acceptedAt: json['acceptedAt'] != null
            ? DateTime.parse(json['acceptedAt'] as String)
            : null,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );
}
