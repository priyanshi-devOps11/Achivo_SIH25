class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error.toString().contains('Invalid login credentials')) {
      return 'Invalid email or password';
    } else if (error.toString().contains('Email already registered')) {
      return 'This email is already registered';
    } else if (error
        .toString()
        .contains('Password should be at least 6 characters')) {
      return 'Password must be at least 6 characters long';
    }
    return 'An unexpected error occurred';
  }
}
