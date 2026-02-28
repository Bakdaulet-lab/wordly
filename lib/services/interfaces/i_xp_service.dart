/// Contract for XP awarding operations.
abstract class IXpService {
  /// Award [amount] XP to [userId], updating total_xp and level.
  Future<void> awardXp(String userId, int amount);
}
