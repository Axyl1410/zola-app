class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.emailVerified,
    this.image,
    this.createdAt,
    this.updatedAt,
    this.lastLoginMethod,
    this.role,
    this.banned = false,
    this.banReason,
    this.banExpires,
  });

  final String id;
  final String name;
  final String email;
  final bool emailVerified;
  final String? image;
  final String? createdAt;
  final String? updatedAt;
  final String? lastLoginMethod;
  final String? role;
  final bool banned;
  final String? banReason;
  final String? banExpires;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'emailVerified': emailVerified,
      'image': image,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastLoginMethod': lastLoginMethod,
      'role': role,
      'banned': banned,
      'banReason': banReason,
      'banExpires': banExpires,
    };
  }

  static AuthUser? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final email = json['email'];
    final emailVerified = json['emailVerified'];
    if (id is! String || name is! String || email is! String) {
      return null;
    }

    final normalizedEmailVerified = emailVerified is bool
        ? emailVerified
        : false;
    final image = json['image'];
    final createdAt = json['createdAt'];
    final updatedAt = json['updatedAt'];
    final lastLoginMethodRaw =
        json['lastLoginMethod'] ?? json['last_login_method'];
    final role = json['role'];
    final banned = json['banned'];
    final banReason = json['banReason'];
    final banExpires = json['banExpires'];

    return AuthUser(
      id: id,
      name: name,
      email: email,
      emailVerified: normalizedEmailVerified,
      image: image is String ? image : null,
      createdAt: createdAt is String ? createdAt : null,
      updatedAt: updatedAt is String ? updatedAt : null,
      lastLoginMethod: lastLoginMethodRaw is String ? lastLoginMethodRaw : null,
      role: role is String ? role : null,
      banned: banned is bool ? banned : false,
      banReason: banReason is String ? banReason : null,
      banExpires: banExpires is String ? banExpires : null,
    );
  }
}
