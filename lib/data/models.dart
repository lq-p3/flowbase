import '../core/tokens.dart';

enum Priority { low, medium, high, urgent }

enum TaskStatus { todo, inProgress, done }

/// A piece of text available in English and Arabic.
/// User-created content stores the same text in both.
class LText {
  const LText(this.en, this.ar);
  const LText.same(String v)
      : en = v,
        ar = v;
  final String en;
  final String ar;

  String of(bool isAr) => isAr && ar.isNotEmpty ? ar : en;
  bool get isEmpty => en.isEmpty && ar.isEmpty;
  bool contains(String q) => en.toLowerCase().contains(q) || ar.contains(q);
}

class Space {
  Space({
    required this.id,
    required this.name,
    required this.icon,
    required this.tone,
    this.description = const LText('', ''),
  });

  final String id;
  LText name;
  String icon;
  Tone tone;
  LText description;
}

class Project {
  Project({
    required this.id,
    required this.spaceId,
    required this.name,
    required this.due,
    this.icon = 'folder',
    this.notes = const LText('', ''),
  });

  final String id;
  String spaceId;
  LText name;
  DateTime due;
  String icon;
  LText notes;
}

class SubTask {
  SubTask({required this.id, required this.title, this.done = false});
  final String id;
  LText title;
  bool done;

  SubTask copy() => SubTask(id: id, title: title, done: done);
}

class Task {
  Task({
    required this.id,
    required this.title,
    required this.spaceId,
    this.projectId,
    required this.date,
    this.time,
    this.priority = Priority.medium,
    this.status = TaskStatus.todo,
    this.description = const LText('', ''),
    this.notes = const LText('', ''),
    List<SubTask>? subtasks,
    this.reminder = true,
  }) : subtasks = subtasks ?? [];

  final String id;
  LText title;
  String spaceId;
  String? projectId;
  DateTime date;

  /// 24h 'HH:mm', or null for "anytime".
  String? time;
  Priority priority;
  TaskStatus status;
  LText description;
  LText notes;
  List<SubTask> subtasks;
  bool reminder;

  bool get isDone => status == TaskStatus.done;

  /// Sort key: date then time (tasks without a time go last in their day).
  String get sortKey =>
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}${time ?? '99:99'}';
}

class ProjectStats {
  const ProjectStats(this.total, this.done);
  final int total;
  final int done;
  int get remaining => total - done;
  double get ratio => total == 0 ? 0 : done / total;
  int get percent => (ratio * 100).round();
}

class TaskFilters {
  const TaskFilters({
    this.status = 'all',
    this.priorities = const {},
    this.spaces = const {},
    this.projectId,
    this.due,
    this.customDate,
  });

  /// 'all' | 'active' | 'completed'
  final String status;
  final Set<Priority> priorities;
  final Set<String> spaces;
  final String? projectId;

  /// null | 'today' | 'tomorrow' | 'week' | 'custom'
  final String? due;
  final DateTime? customDate;

  int get count =>
      (status != 'all' ? 1 : 0) + priorities.length + spaces.length + (projectId != null ? 1 : 0) + (due != null ? 1 : 0);

  bool matches(Task t, DateTime today) {
    if (status == 'active' && t.isDone) return false;
    if (status == 'completed' && !t.isDone) return false;
    if (priorities.isNotEmpty && !priorities.contains(t.priority)) return false;
    if (spaces.isNotEmpty && !spaces.contains(t.spaceId)) return false;
    if (projectId != null && t.projectId != projectId) return false;
    final diff = t.date.difference(today).inDays;
    final daysLeftInWeek = 6 - (today.weekday % 7); // week ends Saturday
    final c = customDate;
    if (due == 'today' && diff != 0) return false;
    if (due == 'tomorrow' && diff != 1) return false;
    if (due == 'week' && (diff < 0 || diff > daysLeftInWeek)) return false;
    if (due == 'custom' && c != null && t.date.difference(DateTime.utc(c.year, c.month, c.day)).inDays != 0) return false;
    return true;
  }
}
