import 'package:shared_preferences/shared_preferences.dart';

/// Manages per-device word favourites in shared preferences.
class FavoritesService {
  static const String _key = 'favorite_word_ids';

  Future<Set<int>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? [];
    return ids.map((e) => int.tryParse(e)).whereType<int>().toSet();
  }

  Future<void> toggleFavorite(int wordId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? [];
    final set = ids.toSet();
    final idStr = wordId.toString();

    if (set.contains(idStr)) {
      set.remove(idStr);
    } else {
      set.add(idStr);
    }

    await prefs.setStringList(_key, set.toList());
  }

  Future<bool> isFavorite(int wordId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? [];
    return ids.contains(wordId.toString());
  }
}
