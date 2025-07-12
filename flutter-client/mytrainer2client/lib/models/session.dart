/// Domain model for one workout / PT session on the calendar timeline.
class Session {
  final int id;
  final DateTime start;   // inclusive
  final DateTime end;     // exclusive
  final List<String> clients;

  Session({
    required this.id,
    required this.start,
    required this.end,
    required this.clients,
  });

  int get durationMinutes => end.difference(start).inMinutes;
}
