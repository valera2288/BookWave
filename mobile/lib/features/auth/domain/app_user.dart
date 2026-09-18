class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.emailVerified,
    required this.avatar,
    required this.theme,
    required this.language,
  });

  final int id;
  final String email;
  final String name;
  final String role;
  final bool emailVerified;
  final String? avatar;
  final String theme;
  final String language;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as int,
        email: json['email'] as String,
        name: json['name'] as String,
        role: json['role'] as String,
        emailVerified: json['email_verified'] as bool,
        avatar: json['avatar'] as String?,
        theme: json['theme'] as String,
        language: json['language'] as String,
      );
}
