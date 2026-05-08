import 'package:burgess_go/core/models/user/user_profile.dart';

class AuthState {
  final UserProfile? user;
  final bool isInitializing;

  AuthState({this.user, this.isInitializing = true});

  AuthState copyWith({UserProfile? user, bool? isInitializing}) {
    return AuthState(
      user: user ?? this.user,
      isInitializing: isInitializing ?? this.isInitializing,
    );
  }
}
