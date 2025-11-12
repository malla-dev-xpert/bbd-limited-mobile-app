class User {
  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;
  final String? roleName;
  final Role? role; // 👈 Ajouté ici
  final String? password; // 👈 Ajouté pour la création d'utilisateur
  final String? branchName; // 👈 Ajouté pour la branche/pays

  User({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.roleName,
    this.role,
    this.password, // 👈 Ajouté ici
    this.branchName, // 👈 Ajouté pour la branche/pays
  });

  User copyWith({
    int? id,
    String? username,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? roleName,
    Role? role,
    String? password, // 👈 Ajouté ici
    String? branchName, // 👈 Ajouté pour la branche/pays
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      roleName: roleName ?? this.roleName,
      role: role ?? this.role,
      password: password ?? this.password, // 👈 Ajouté ici
      branchName:
          branchName ?? this.branchName, // 👈 Ajouté pour la branche/pays
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      roleName: json['roleName'] as String?,
      role: json['role'] != null ? Role.fromJson(json['role']) : null,
      password: json['password'] as String?, // 👈 Ajouté ici
      branchName:
          json['branchName'] as String?, // 👈 Ajouté pour la branche/pays
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'roleName': roleName,
      'role': role?.toJson(),
      'branchCode': branchName, // Le backend attend branchCode, pas branchName
    };

    // Ajouter le mot de passe seulement s'il est fourni (pour la création)
    if (password != null) {
      data['password'] = password;
    }

    return data;
  }
}

class Role {
  final int id;
  final String name;
  final List<String> permissions;

  Role({required this.id, required this.name, required this.permissions});

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as int,
      name: json['name'] as String,
      permissions: List<String>.from(json['permissions']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'permissions': permissions};
  }
}
