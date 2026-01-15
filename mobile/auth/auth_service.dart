import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import '../app/config/app_config.dart';
import '../models/auth_user.dart';
import 'session_manager.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _fa = FirebaseAuth.instance;

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: kApiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );


  // Google Sign-In

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // GOOGLE SIGN IN
  Future<AuthUser?> signInWithGoogle({required bool remember}) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _fa.signInWithCredential(credential);
      final idToken = await userCredential.user!.getIdToken();

      final jwt = await _exchangeIdTokenForJwt(idToken);
      if (jwt != null) {
        await SessionManager.instance.persistJwt(jwt, remember: remember);
      }

      return AuthUser(
        uid: userCredential.user!.uid,
        email: userCredential.user!.email,
        jwt: jwt,
        name: userCredential.user!.displayName,
        phone: userCredential.user!.phoneNumber,
      );
    } catch (e) {
      print('Google Sign-In failed: $e');
      rethrow;
    }
  }

  // Optional: sign-out from Google as well
  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
    await signOut();
  }


  // Email / Password

  Future<AuthUser> loginWithEmail({
    required String email,
    required String password,
    required bool remember,
  }) async {
    final cred = await _fa.signInWithEmailAndPassword(email: email, password: password);
    final idToken = await cred.user!.getIdToken(true);
    final jwt = await _exchangeIdTokenForJwt(idToken);
    if (jwt != null) {
      await SessionManager.instance.persistJwt(jwt, remember: remember);
    }
    return AuthUser(uid: cred.user!.uid, email: cred.user!.email ?? email, jwt: jwt);
  }

  Future<AuthUser> registerWithEmail({
    required String email,
    required String password,
    required String phone,
    String? name,
    required bool remember,
    required String role, // for role
  }) async {
    final cred = await _fa.createUserWithEmailAndPassword(email: email, password: password);
    final idToken = await cred.user!.getIdToken(true);

    final jwt = await _exchangeIdTokenForJwt(
      idToken,
      phone: phone,
      name: name,
      role: role,   // send role to backend
    );

    if (jwt != null) {
      await SessionManager.instance.persistJwt(jwt, remember: remember);
    }

    return AuthUser(
      uid: cred.user!.uid,
      email: cred.user!.email ?? email,
      jwt: jwt,
      phone: phone,
      name: name,
    );
  }

  Future<void> sendPasswordReset(String email) async {
    await _fa.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _fa.signOut();
    await SessionManager.instance.clear();
  }


  // Token exchange (phone + name optional)

  Future<String?> _exchangeIdTokenForJwt(
      String? idToken, {
        String? phone,
        String? name,
        String? role,
      }) async {
    if (idToken == null || idToken.isEmpty) return null;

    try {
      final data = <String, dynamic>{'idToken': idToken};

      if (phone != null && phone.isNotEmpty) data['phone'] = phone.trim();
      if (name != null && name.isNotEmpty) data['name'] = name.trim();
      if(role !=null && role.isNotEmpty) data['role'] = role;

      final res = await _dio.post('/auth/exchange', data: data);
      return res.data['jwt'] as String?;
    } catch (e) {
      print('JWT exchange failed: $e');
      return null;
    }
  }
}