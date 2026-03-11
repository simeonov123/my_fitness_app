class ClientFolder {
  final int id;
  final String name;
  final int? sequenceOrder;
  final int clientCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ClientFolder({
    required this.id,
    required this.name,
    this.sequenceOrder,
    this.clientCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory ClientFolder.fromJson(Map<String, dynamic> j) => ClientFolder(
        id: j['id'] as int,
        name: j['name'] as String,
        sequenceOrder: j['sequenceOrder'] as int?,
        clientCount: (j['clientCount'] as num?)?.toInt() ?? 0,
        createdAt: j['createdAt'] != null
            ? DateTime.parse(j['createdAt'] as String)
            : null,
        updatedAt: j['updatedAt'] != null
            ? DateTime.parse(j['updatedAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sequenceOrder': sequenceOrder,
      };
}
