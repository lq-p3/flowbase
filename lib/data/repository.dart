import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/tokens.dart';
import 'models.dart';

/// Random UUID v4, so rows can be created on the phone before the server answers.
String newUuid() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

String _day(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime _parseDay(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime.utc(p[0], p[1], p[2]);
}

/// Reads and writes FlowBase data in Supabase. Row Level Security on the server
/// limits every query to the signed-in user's own rows, so no user filter is needed here.
class Repository {
  Repository(this._db);
  final SupabaseClient _db;

  // ---------- Load ----------
  Future<(List<Space>, List<Project>, List<Task>)> loadAll() async {
    final results = await Future.wait([
      _db.from('spaces').select().order('created_at'),
      _db.from('projects').select().order('created_at'),
      _db.from('tasks').select('*, subtasks(*)').order('date'),
    ]);
    final spaces = results[0].map(_space).toList();
    final projects = results[1].map(_project).toList();
    final tasks = results[2].map(_task).toList();
    return (spaces, projects, tasks);
  }

  Space _space(Map<String, dynamic> r) => Space(
        id: r['id'] as String,
        name: LText.same(r['name'] as String),
        icon: r['icon'] as String,
        tone: Tone.values.byName(r['tone'] as String),
        description: LText.same(r['description'] as String),
      );

  Project _project(Map<String, dynamic> r) => Project(
        id: r['id'] as String,
        spaceId: r['space_id'] as String,
        name: LText.same(r['name'] as String),
        due: _parseDay(r['due'] as String),
        icon: r['icon'] as String,
        notes: LText.same(r['notes'] as String),
      );

  Task _task(Map<String, dynamic> r) {
    final subs = (r['subtasks'] as List? ?? []).cast<Map<String, dynamic>>()
      ..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));
    final time = r['time'] as String?;
    return Task(
      id: r['id'] as String,
      title: LText.same(r['title'] as String),
      spaceId: r['space_id'] as String,
      projectId: r['project_id'] as String?,
      date: _parseDay(r['date'] as String),
      time: time?.substring(0, 5),
      priority: Priority.values.byName(r['priority'] as String),
      status: TaskStatus.values.byName(r['status'] as String),
      description: LText.same(r['description'] as String),
      notes: LText.same(r['notes'] as String),
      reminder: r['reminder'] as bool,
      subtasks: [for (final s in subs) SubTask(id: s['id'] as String, title: LText.same(s['title'] as String), done: s['done'] as bool)],
    );
  }

  // ---------- Write ----------
  Future<void> upsertSpace(Space s) => _db.from('spaces').upsert({
        'id': s.id,
        'name': s.name.en,
        'description': s.description.en,
        'icon': s.icon,
        'tone': s.tone.name,
      });

  Future<void> upsertSpaces(List<Space> list) => _db.from('spaces').upsert([
        for (final s in list) {'id': s.id, 'name': s.name.en, 'description': s.description.en, 'icon': s.icon, 'tone': s.tone.name},
      ]);

  Future<void> deleteSpace(String id) => _db.from('spaces').delete().eq('id', id);

  Future<void> upsertProject(Project p) => _db.from('projects').upsert({
        'id': p.id,
        'space_id': p.spaceId,
        'name': p.name.en,
        'notes': p.notes.en,
        'icon': p.icon,
        'due': _day(p.due),
      });

  /// Deletes the project and its tasks (the app removes them together).
  Future<void> deleteProject(String id) async {
    await _db.from('tasks').delete().eq('project_id', id);
    await _db.from('projects').delete().eq('id', id);
  }

  /// Saves the task and replaces its subtasks with the current list.
  Future<void> upsertTask(Task t) async {
    await _db.from('tasks').upsert({
      'id': t.id,
      'space_id': t.spaceId,
      'project_id': t.projectId,
      'title': t.title.en,
      'description': t.description.en,
      'notes': t.notes.en,
      'date': _day(t.date),
      'time': t.time,
      'priority': t.priority.name,
      'status': t.status.name,
      'reminder': t.reminder,
    });
    final ids = [for (final s in t.subtasks) s.id];
    var del = _db.from('subtasks').delete().eq('task_id', t.id);
    if (ids.isNotEmpty) del = del.not('id', 'in', '(${ids.join(',')})');
    await del;
    if (t.subtasks.isNotEmpty) {
      await _db.from('subtasks').upsert([
        for (var i = 0; i < t.subtasks.length; i++)
          {'id': t.subtasks[i].id, 'task_id': t.id, 'title': t.subtasks[i].title.en, 'done': t.subtasks[i].done, 'position': i},
      ]);
    }
  }

  Future<void> deleteTask(String id) => _db.from('tasks').delete().eq('id', id);

  /// Removes every row the user owns (spaces cascade to projects, tasks and subtasks).
  Future<void> deleteAllData() => _db.from('spaces').delete().not('id', 'is', null);
}
