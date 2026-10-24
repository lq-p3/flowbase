import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/mock_data.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../widgets/overlays.dart';

/// Today's calendar day (UTC date of the phone's local day).
DateTime get kToday => dayOnly(DateTime.now());

DateTime dayOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);
bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// Single source of truth for the app.
///
/// With a Supabase client ([db]) the lists are loaded from the server after sign-in,
/// and every change is applied here first (so the UI is instant) and then saved.
/// Without one (tests), it runs on the local mock data.
class AppState extends ChangeNotifier {
  AppState({this.db}) : _repo = db == null ? null : Repository(db) {
    if (db == null) {
      _seed();
    } else {
      _clear();
    }
  }

  final SupabaseClient? db;
  final Repository? _repo;

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
  bool loading = false;

  void _seed() {
    spaces = mockSpaces();
    projects = mockProjects();
    tasks = mockTasks();
    recent = ['Deep Learning', 'Mobile App', 'Portfolio'];
    filters = const TaskFilters();
    tab = 0;
  }

  void _clear() {
    spaces = [];
    projects = [];
    tasks = [];
    recent = [];
    filters = const TaskFilters();
    tab = 0;
  }

  bool get isAr => lang == 'ar';
  Locale get locale => Locale(lang);

  String newId(String prefix) => newUuid();

  // ---------- Account ----------
  User? get user => db?.auth.currentUser;
  bool get signedIn => user != null;
  String get userName => (user?.userMetadata?['full_name'] as String?)?.trim() ?? '';
  String get email => user?.email ?? '';

  /// Signs in and loads the user's data. Returns an error message, or null on success.
  Future<String?> signIn(String email, String password) async {
    try {
      await db!.auth.signInWithPassword(email: email, password: password);
      await load();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return '$e';
    }
  }

  /// Creates the account. Returns (error, needsEmailConfirm).
  Future<(String?, bool)> signUp(String name, String email, String password) async {
    try {
      final res = await db!.auth.signUp(email: email, password: password, data: {'full_name': name});
      if (res.session == null) return (null, true);
      await load();
      return (null, false);
    } on AuthException catch (e) {
      return (e.message, false);
    } catch (e) {
      return ('$e', false);
    }
  }

  Future<void> signOut() async {
    try {
      await db?.auth.signOut();
    } catch (_) {}
    _clear();
    notifyListeners();
  }

  /// Deletes every row the user owns, then signs out.
  Future<void> deleteAllData() async {
    await _repo?.deleteAllData();
    await signOut();
  }

  /// Loads everything from Supabase. A brand-new user gets the four starter spaces.
  Future<void> load() async {
    final repo = _repo;
    if (repo == null || !signedIn) return;
    loading = true;
    notifyListeners();
    try {
      final (s, p, t) = await repo.loadAll();
      spaces = s;
      projects = p;
      tasks = t;
      if (spaces.isEmpty) {
        spaces = [
          for (final m in mockSpaces())
            Space(id: newUuid(), name: LText.same(m.name.of(isAr)), icon: m.icon, tone: m.tone, description: LText.same(m.description.of(isAr))),
        ];
        await repo.upsertSpaces(spaces);
      }
    } catch (e) {
      showToast('Could not load data: $e', icon: Icons.cloud_off_rounded);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Saves a change in the background; shows a message if it fails.
  void _save(Future<void> Function(Repository r) op) {
    final repo = _repo;
    if (repo == null) return;
    op(repo).catchError((Object e) {
      showToast('Not saved: $e', icon: Icons.cloud_off_rounded);
    });
  }

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
    _save((r) => r.upsertTask(t));
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
    _save((r) => r.upsertTask(t));
    return t.isDone;
  }

  void toggleSub(String taskId, String subId) {
    final t = task(taskId);
    if (t == null) return;
    for (final s in t.subtasks) {
      if (s.id == subId) s.done = !s.done;
    }
    notifyListeners();
    _save((r) => r.upsertTask(t));
  }

  void addSub(String taskId, String title) {
    final t = task(taskId);
    if (t == null || title.trim().isEmpty) return;
    t.subtasks.add(SubTask(id: newId('s'), title: LText.same(title.trim())));
    notifyListeners();
    _save((r) => r.upsertTask(t));
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
    _save((r) => r.upsertTask(t));
  }

  void deleteTask(String id) {
    tasks.removeWhere((t) => t.id == id);
    notifyListeners();
    _save((r) => r.deleteTask(id));
  }

  // ---------- Spaces & projects ----------
  void addSpace(Space s) {
    spaces.add(s);
    notifyListeners();
    _save((r) => r.upsertSpace(s));
  }

  void deleteSpace(String id) {
    spaces.removeWhere((s) => s.id == id);
    projects.removeWhere((p) => p.spaceId == id);
    tasks.removeWhere((t) => t.spaceId == id);
    notifyListeners();
    _save((r) => r.deleteSpace(id));
  }

  void addProject(Project p) {
    projects.add(p);
    notifyListeners();
    _save((r) => r.upsertProject(p));
  }

  void deleteProject(String id) {
    projects.removeWhere((p) => p.id == id);
    tasks.removeWhere((t) => t.projectId == id);
    notifyListeners();
    _save((r) => r.deleteProject(id));
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

  /// Restores the mock data (tests / offline demo only).
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
