class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'];
    final emailValue = json['email'];
    
    if (idValue == null || emailValue == null) {
      throw FormatException('UserModel requires id and email fields');
    }
    
    return UserModel(
      id: idValue.toString(),
      email: emailValue.toString(),
      displayName: json['display_name']?.toString(),
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}

