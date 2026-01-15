class AuthUser {
  final String uid;
  final String? email;
  final String? jwt;    //  backend token after exchange
  final String? phone;  // From registration
  final String? name;   // From registration

  AuthUser({
    required this.uid,
    this.email,
    this.jwt,
    this.phone,
    this.name,
  });
}