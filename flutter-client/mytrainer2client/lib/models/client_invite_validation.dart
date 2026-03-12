class ClientInviteValidation {
  final bool valid;
  final String status;
  final String trainerName;
  final int clientId;
  final String clientName;
  final String? clientEmail;
  final bool alreadyLinked;

  const ClientInviteValidation({
    required this.valid,
    required this.status,
    required this.trainerName,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.alreadyLinked,
  });

  factory ClientInviteValidation.fromJson(Map<String, dynamic> json) {
    return ClientInviteValidation(
      valid: json['valid'] == true,
      status: (json['status'] as String?) ?? 'UNKNOWN',
      trainerName: (json['trainerName'] as String?) ?? '',
      clientId: (json['clientId'] as num?)?.toInt() ?? 0,
      clientName: (json['clientName'] as String?) ?? '',
      clientEmail: json['clientEmail'] as String?,
      alreadyLinked: json['alreadyLinked'] == true,
    );
  }
}
