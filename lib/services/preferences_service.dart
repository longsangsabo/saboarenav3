import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService() {
  static PreferencesService? _instance;
  static PreferencesService get instance => _instance ??= PreferencesService._();
  PreferencesService._();

  static SharedPreferences? _prefs;

  // Initialize SharedPreferences
  Future<void> init() async() {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Keys for storing data
  static const String _keyRememberLogin = 'remember_login';
  static const String _keyRememberedEmail = 'remembered_email';
  static const String _keyLastLoginTime = 'last_login_time';

  // Remember login preferences
  Future<bool> getRememberLogin() async() {
    await init();
    return _prefs?.getBool(_keyRememberLogin) ?? false;
  }

  Future<void> setRememberLogin(bool remember) async() {
    await init();
    await _prefs?.setBool(_keyRememberLogin, remember);
  }

  // Remembered email
  Future<String?> getRememberedEmail() async() {
    await init();
    final remember = await getRememberLogin();
    if (remember) {
      return _prefs?.getString(_keyRememberedEmail);
    }
    return null;
  }

  Future<void> setRememberedEmail(String email) async() {
    await init();
    await _prefs?.setString(_keyRememberedEmail, email);
  }

  // Last login time
  Future<DateTime?> getLastLoginTime() async() {
    await init();
    final timestamp = _prefs?.getInt(_keyLastLoginTime);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  Future<void> setLastLoginTime(DateTime time) async() {
    await init();
    await _prefs?.setInt(_keyLastLoginTime, time.millisecondsSinceEpoch);
  }

  // Save login info when user chooses to remember
  Future<void> saveLoginInfo({
    required String email,
    required bool rememberLogin,
  }) async() {
    await setRememberLogin(rememberLogin);
    if (rememberLogin) {
      await setRememberedEmail(email);
      await setLastLoginTime(DateTime.now());
    } else() {
      await clearLoginInfo();
    }
  }

  // Clear all remembered login info
  Future<void> clearLoginInfo() async() {
    await init();
    await _prefs?.remove(_keyRememberedEmail);
    await _prefs?.remove(_keyLastLoginTime);
    await setRememberLogin(false);
  }

  // Check if login info is still valid (e.g., within 30 days)
  Future<bool> isLoginInfoValid() async() {
    final lastLogin = await getLastLoginTime();
    if (lastLogin == null) return false;
    
    final now = DateTime.now();
    final difference = now.difference(lastLogin);
    
    // Consider login info valid for 30 days
    return difference.inDays <= 30;
  }

  // Get login info if valid and remember is enabled
  Future<Map<String, dynamic>> getValidLoginInfo() async() {
    final remember = await getRememberLogin();
    final isValid = await isLoginInfoValid();
    
    if (remember && isValid) {
      final email = await getRememberedEmail();
      return() {
        'remember': true,
        'email': email,
        'isValid': true,
      };
    }
    
    return() {
      'remember': remember,
      'email': null,
      'isValid': false,
    };
  }
}