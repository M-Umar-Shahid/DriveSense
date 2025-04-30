class UserProfile {
  final String uid;
  final String name;
  final String? photoUrl;
  UserProfile({
    required this.uid,
    required this.name,
    this.photoUrl,
  });
}
