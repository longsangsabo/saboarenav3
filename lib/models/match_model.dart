class Match() {
  final String id;
  final dynamic player1;
  final dynamic player2;
  final dynamic winner;
  final int round;

  Match({
    required this.id,
    this.player1,
    this.player2,
    this.winner,
    required this.round,
  });
}
