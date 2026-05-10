/// Domain entity representing a VibeTalk user.
/// This is pure Dart — no framework dependencies.
class UserEntity {
  final String id;
  final String phoneNumber;
  final String? name;
  final String? username;
  final String? avatarUrl;
  final String? bio;
  final String status;
  final DateTime? lastSeen;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.id,
    required this.phoneNumber,
    this.name,
    this.username,
    this.avatarUrl,
    this.bio,
    this.status = 'active',
    this.lastSeen,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get the username with an '@' prefix
  String get atUsername => username != null ? '@$username' : '';

  /// True when the user has completed their profile (has a name and username).
  bool get isProfileComplete => name != null && name!.trim().isNotEmpty && username != null && username!.trim().isNotEmpty;

  UserEntity copyWith({
    String? id,
    String? phoneNumber,
    String? name,
    String? username,
    String? avatarUrl,
    String? bio,
    String? status,
    DateTime? lastSeen,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      id: map['id'] as String,
      phoneNumber: map['phone_number'] ?? map['email'] as String, // Using phone_number or email based on backend structure.
      name: map['name'] as String?,
      username: map['username'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      bio: map['bio'] as String?,
      status: map['status'] as String? ?? 'active',
      lastSeen: map['last_seen'] != null
          ? DateTime.tryParse(map['last_seen'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(
        map['updated_at'] as String? ?? map['created_at'] as String,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'phone_number': phoneNumber,
        'name': name,
        'username': username,
        'avatar_url': avatarUrl,
        'bio': bio,
        'status': status,
        'last_seen': lastSeen?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'UserEntity(id: $id, phone: $phoneNumber, name: $name, username: $username)';
}
