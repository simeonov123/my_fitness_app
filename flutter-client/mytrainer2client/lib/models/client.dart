/// Simple mutable model that matches the JSON shape coming from the backend.
class Client {
  int id;
  String fullName;
  String? email;
  String? phone;
  DateTime? createdAt;
  DateTime? updatedAt;

  Client({
    this.id = 0,
    required this.fullName,
    this.email,
    this.phone,
    this.createdAt,
    this.updatedAt,
  });

  factory Client.fromJson(Map<String, dynamic> j) => Client(
    id:        (j['id']        ?? 0) as int,
    fullName:  (j['fullName']  ?? '') as String,
    email:      j['email']  as String?,
    phone:      j['phone']  as String?,
    createdAt:  j['createdAt'] != null
        ? DateTime.parse(j['createdAt'] as String)
        : null,
    updatedAt:  j['updatedAt'] != null
        ? DateTime.parse(j['updatedAt'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id'      : id,
    'fullName': fullName,
    'email'   : email,
    'phone'   : phone,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };
}
