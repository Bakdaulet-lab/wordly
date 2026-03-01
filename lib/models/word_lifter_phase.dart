/// Represents the current phase of the Word Lifter mini-game.
enum WordLifterPhase {
  /// Game is ready to start, showing intro/instructions.
  ready,

  /// A question is being displayed and the player can answer.
  playing,

  /// Player completed 5 correct in a row — rep success animation.
  repSuccess,

  /// Player answered wrong or timed out — drop animation.
  repFail,

  /// Game is over (max failed reps reached).
  finished,
}
