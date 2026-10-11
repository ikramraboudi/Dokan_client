/// ============================================================
///  SOUKNA — MODÈLE UTILISATEUR SOMMAIRE
/// ============================================================
class UserSummary {
  final String fullName;
  final String email;

  const UserSummary({
    required this.fullName,
    required this.email,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSummary &&
          runtimeType == other.runtimeType &&
          fullName == other.fullName &&
          email == other.email;

  @override
  int get hashCode => fullName.hashCode ^ email.hashCode;
}
