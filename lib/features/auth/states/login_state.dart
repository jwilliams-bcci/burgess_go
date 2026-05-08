class LoginState {
  final bool isLoading;
  final bool isLoginMode;
  final String? errorMessage;

  LoginState({
    this.isLoading = false,
    this.isLoginMode = true,
    this.errorMessage,
  });

  LoginState copyWith({
    bool? isLoading,
    bool? isLoginMode,
    String? errorMessage,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      isLoginMode: isLoginMode ?? this.isLoginMode,
      errorMessage: errorMessage,
    );
  }
}
