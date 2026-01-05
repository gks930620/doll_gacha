class User {
  final int id;
  final String username;
  final String email;
  final String nickname;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.nickname,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      nickname: json['nickname'] ?? '',
    );
  }
}

