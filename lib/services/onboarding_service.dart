import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const _keySeen = 'hasSeenOnboarding';

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySeen, true);
  }

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySeen) ?? false;
  }
}
