import 'package:shared_preferences/shared_preferences.dart';

class DailyGoalService {
  static const String _goalKey = 'daily_xp_goal';
  static const int defaultGoal = 50;

  Future<int> getGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_goalKey) ?? defaultGoal;
  }

  Future<void> setGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_goalKey, goal);
  }
}
