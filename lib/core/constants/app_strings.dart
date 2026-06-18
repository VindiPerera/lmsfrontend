/// Centralized strings for the JAAN LMS app to ensure consistency
/// and make future localization (translations) easier.
class AppStrings {
  AppStrings._();

  // ── Branding ─────────────────────────────────────────────
  static const String appName = 'FaceTalk';
  static const String appTagline = 'Learning Management System';

  // ── Common Button Labels ─────────────────────────────────
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String submit = 'Submit';
  static const String back = 'Back to Home';
  static const String login = 'Login';
  static const String register = 'Register';
  static const String logout = 'Sign Out';

  // ── Common Error Messages ────────────────────────────────
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorConnection =
      'No internet connection. Please check your network.';
  static const String errorTimeout = 'Connection timed out. Please try again.';
  static const String errorRequiredField = 'This field is required.';
  static const String errorInvalidEmail = 'Please enter a valid email address.';
  static const String errorPasswordTooShort =
      'Password must be at least 6 characters.';

  // ── Success Messages ─────────────────────────────────────
  static const String successSaved = 'Saved successfully.';
  static const String successUpdated = 'Profile updated successfully.';
}
