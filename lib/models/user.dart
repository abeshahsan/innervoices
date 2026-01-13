import 'dart:convert';

class User {
  String username;
  String fullName;
  String email;
  String profilePictureUrl;
  User({
    required this.username,
    required this.fullName,
    required this.email,
    required this.profilePictureUrl,
  });

  User copyWith({
    String? username,
    String? fullName,
    String? email,
    String? profilePictureUrl,
  }) {
    return User(
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'username': username,
      'fullName': fullName,
      'email': email,
      'profilePictureUrl': profilePictureUrl,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      username: map['username'] as String,
      fullName: map['fullName'] as String,
      email: map['email'] as String,
      profilePictureUrl: map['profilePictureUrl'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) =>
      User.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'User(username: $username, fullName: $fullName, email: $email, profilePictureUrl: $profilePictureUrl)';
  }

  @override
  bool operator ==(covariant User other) {
    if (identical(this, other)) return true;

    return other.username == username &&
        other.fullName == fullName &&
        other.email == email &&
        other.profilePictureUrl == profilePictureUrl;
  }

  @override
  int get hashCode {
    return username.hashCode ^
        fullName.hashCode ^
        email.hashCode ^
        profilePictureUrl.hashCode;
  }
}
