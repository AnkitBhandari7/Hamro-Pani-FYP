import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fyp/core/models/auth_user.dart';
import 'package:fyp/features/resident/profile/services/session_manager.dart';

class AuthService {
  final FirebaseAuth _fa = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  // GOOGLE SIGN IN

  Future<AuthUser?> signInWithGoogle({required bool remember}) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _fa.signInWithCredential(credential);

      return AuthUser(
        uid: userCredential.user!.uid,
        email: userCredential.user!.email,
        name: userCredential.user!.displayName,
        phone: userCredential.user!.phoneNumber,
      );
    } catch (e) {
      print('Google Sign-In failed: $e');
      rethrow;
    }
  }

  // EMAIL / PASSWORD LOGIN

  Future<AuthUser> loginWithEmail({
    required String email,
    required String password,
    required bool remember,
  }) async {
    final cred = await _fa.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return AuthUser(uid: cred.user!.uid, email: cred.user!.email ?? email);
  }

  // REGISTER

  Future<AuthUser> registerWithEmail({
    required String email,
    required String password,
    required String phone,
    String? name,
    required bool remember,
    required String role,
  }) async {
    final cred = await _fa.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    return AuthUser(
      uid: cred.user!.uid,
      email: cred.user!.email ?? email,
      phone: phone,
      name: name,
    );
  }

  // PASSWORD RESET

  Future<void> sendPasswordReset(String email) async {
    await _fa.sendPasswordResetEmail(email: email);
  }

  // LOGOUT

  Future<void> signOut() async {
    await _fa.signOut();
    await _googleSignIn.signOut();
    await SessionManager.instance.clear();
  }
}
