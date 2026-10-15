import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/models.dart';

/// The prototype's "today" — Monday, October 26, 2026 (UTC calendar day).
final DateTime kToday = DateTime.utc(2026, 10, 26);

DateTime dayOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);
bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// Single source of truth for the whole prototype (local mock state only — no backend).
class AppState extends ChangeNotifier {
  AppState() {
    _seed();
  }

  late List<Space> spaces;
  late List<Project> projects;
  late List<Task> tasks;

  ThemeMode themeMode = ThemeMode.light;
  String lang = 'en';
  int tab = 0;
  TaskFilters filters = const TaskFilters();
  List<String> recent = [];
  bool notifTasks = true;
  bool notifDue = true;
  int _seq = 0;

  void _seed() {
    spaces = mockSpaces();
    projects = mockProjects();
    tasks = mockTasks();
    recent = ['Deep Learning', 'Mobile App', 'Portfolio'];
    filters = const TaskFilters();
    tab = 0;
  }

  bool get isAr => lang == 'ar';
  Locale get locale => Locale(lang);

  String newId(String prefix) => '$prefix${DateTime.now().microsecondsSinceEpoch}${_seq++}';

  // ---------- Lookups ----------
  Space? space(String? id) {
    for (final s in spaces) {
      if (s.id == id) return s;
    }
    return null;
  }

  Project? project(String? id) {
    for (final p in projects) {
      if (p.id == id) return p;
    }
    return null;
  }

  Task? task(String? id) {
    for (final t in tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  List<Project> projectsIn(String spaceId) => projects.where((p) => p.spaceId == spaceId).toList();
  List<Task> tasksIn(String spaceId) => tasks.where((t) => t.spaceId == spaceId).toList();
  List<Task> tasksOfProject(String projectId) => tasks.where((t) => t.projectId == projectId).toList();
  List<Task> tasksOn(DateTime day) => tasks.where((t) => sameDay(t.date, day)).toList();
  int activeIn(String spaceId) => tasks.where((t) => t.spaceId == spaceId && !t.isDone).length;
  int get completedCount => tasks.where((t) => t.isDone).length;

  ProjectStats stats(String projectId) {
    final list = tasksOfProject(projectId);
    return ProjectStats(list.length, list.where((t) => t.isDone).length);
  }

  List<Project> get activeProjects {
    final list = projects.where((p) {
      final s = stats(p.id);
      return s.remaining > 0 || s.total == 0;
    }).toList();
    list.sort((a, b) => a.due.compareTo(b.due));
    return list;
  }

  // ---------- Preferences ----------
  void setTab(int i) {
    tab = i;
    notifyListeners();
  }

  void setTheme(ThemeMode m) {
    themeMode = m;
    notifyListeners();
  }

  void setLang(String l) {
    lang = l;
    notifyListeners();
  }

  void setNotif({bool? tasksOn, bool? dueOn}) {
    if (tasksOn != null) notifTasks = tasksOn;
    if (dueOn != null) notifDue = dueOn;
    notifyListeners();
  }

  void setFilters(TaskFilters f) {
    filters = f;
    notifyListeners();
  }

  // ---------- Tasks ----------
  /// Returns true when the task became completed.
  bool toggleTask(String id) {
    final t = task(id);
    if (t == null) return false;
    t.status = t.isDone ? TaskStatus.todo : TaskStatus.done;
    notifyListeners();
    return t.isDone;
  }

  /// To Do → In Progress → Completed → To Do. Returns true when completed.
  bool cycleStatus(String id) {
    final t = task(id);
    if (t == null) return false;
    t.status = switch (t.status) {
      TaskStatus.todo => TaskStatus.inProgress,
      TaskStatus.inProgress => TaskStatus.done,
      TaskStatus.done => TaskStatus.todo,
    };
    notifyListeners();
    return t.isDone;
  }

  void toggleSub(String taskId, String subId) {
    final t = task(taskId);
    if (t == null) return;
    for (final s in t.subtasks) {
      if (s.id == subId) s.done = !s.done;
    }
    notifyListeners();
  }

  void addSub(String taskId, String title) {
    final t = task(taskId);
    if (t == null || title.trim().isEmpty) return;
    t.subtasks.add(SubTask(id: newId('s'), title: LText.same(title.trim())));
    notifyListeners();
  }

  /// Adds a new task or replaces an existing one with the same id.
  void saveTask(Task t) {
    final i = tasks.indexWhere((x) => x.id == t.id);
    if (i >= 0) {
      tasks[i] = t;
    } else {
      tasks.add(t);
    }
    notifyListeners();
  }

  void deleteTask(String id) {
    tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // ---------- Spaces & projects ----------
  void addSpace(Space s) {
    spaces.add(s);
    notifyListeners();
  }

  void deleteSpace(String id) {
    spaces.removeWhere((s) => s.id == id);
    projects.removeWhere((p) => p.spaceId == id);
    tasks.removeWhere((t) => t.spaceId == id);
    notifyListeners();
  }

  void addProject(Project p) {
    projects.add(p);
    notifyListeners();
  }

  void deleteProject(String id) {
    projects.removeWhere((p) => p.id == id);
    tasks.removeWhere((t) => t.projectId == id);
    notifyListeners();
  }

  // ---------- Search ----------
  void rememberSearch(String q) {
    final v = q.trim();
    if (v.isEmpty) return;
    recent = [v, ...recent.where((r) => r.toLowerCase() != v.toLowerCase())].take(5).toList();
    notifyListeners();
  }

  void clearRecent() {
    recent = [];
    notifyListeners();
  }

  /// "Delete account" in the prototype: restore the mock data.
  void resetAll() {
    _seed();
    notifyListeners();
  }
}

/// Makes [AppState] available to the widget tree and rebuilds dependents on change.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) =>
      (context.getElementForInheritedWidgetOfExactType<AppScope>()!.widget as AppScope).notifier!;
}
