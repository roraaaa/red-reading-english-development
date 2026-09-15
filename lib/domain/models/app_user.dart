class AppUser {
  const AppUser({
    required this.id,
    required this.displayName,
    required this.email,
  });

  final String id;
  final String displayName;
  final String email;

  String get firstName {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return 'Reader';
    return trimmed.split(RegExp(r'\s+')).first;
  }
}
