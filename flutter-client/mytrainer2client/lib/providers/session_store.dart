import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/session.dart';
import '../providers/auth_provider.dart';
import '../providers/training_sessions_provider.dart';

class SessionStore {
  SessionStore._();
  static final SessionStore _inst = SessionStore._();
  factory SessionStore() => _inst;

  final ValueNotifier<List<Session>> _notifier = ValueNotifier(const []);

  ValueListenable<List<Session>> get listenable => _notifier;
  List<Session> get sessions => _notifier.value;

  void setAll(List<Session> list) =>
      _notifier.value = List.unmodifiable(list);

  void add(Session s) =>
      _notifier.value = [..._notifier.value, s];

  /// Removes the pill *and* dispatches a backend delete.
  Future<void> remove(BuildContext ctx, int id) async {
    final tok = ctx.read<AuthProvider>().token!;
    await ctx
        .read<TrainingSessionsProvider>()
        .deleteOne(token: tok, id: id);

    _notifier.value =
        _notifier.value.where((e) => e.id != id).toList();
  }

  /// Local mock helper
  int nextId() => DateTime.now().microsecondsSinceEpoch;
}
