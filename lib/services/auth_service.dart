// auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _isSigningIn = false;

  Future<User?> signInWithGoogle() async {
    if (_isSigningIn) return null; 
    _isSigningIn = true;

    try {
      // 1. 구글 로그인 창 띄우기
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // 로그인 취소 시

      // 2. 구글 인증 정보 얻기
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Firebase 인증 정보 생성
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Firebase 로그인
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print('Google 로그인 오류: $e');
      return null;
    } finally {
      _isSigningIn = false;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  // 현재 로그인된 유저 가져오기
  User? get currentUser => _auth.currentUser;

  bool get isSigningIn => _isSigningIn;
}
