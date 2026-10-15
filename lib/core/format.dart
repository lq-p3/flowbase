import '../state/app_state.dart' show kToday;

/// Date, time and plural formatting for English and Arabic
/// (kept dependency-free on purpose — no intl package needed).
class Fmt {
  const Fmt(this.ar);
  final bool ar;

  static const _ms = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _ml = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  static const _ma = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
  // Index 0 = Sunday (DateTime.weekday % 7).
  static const _wl = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  static const _w3 = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _wa = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
  static const _was = ['أحد', 'إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت'];

  int _wd(DateTime d) => d.weekday % 7;

  String short(DateTime d) => ar ? '${d.day} ${_ma[d.month - 1]}' : '${_ms[d.month - 1]} ${d.day}';
  String long(DateTime d) =>
      ar ? '${_wa[_wd(d)]}، ${d.day} ${_ma[d.month - 1]}' : '${_wl[_wd(d)]}, ${_ms[d.month - 1]} ${d.day}';
  String full(DateTime d) =>
      ar ? '${_wa[_wd(d)]}، ${d.day} ${_ma[d.month - 1]}' : '${_wl[_wd(d)]}, ${_ml[d.month - 1]} ${d.day}';
  String mid(DateTime d) =>
      ar ? '${_wa[_wd(d)]}، ${d.day} ${_ma[d.month - 1]}' : '${_w3[_wd(d)]}, ${_ms[d.month - 1]} ${d.day}';
  String weekdayShort(DateTime d) => ar ? _was[_wd(d)] : _w3[_wd(d)].toUpperCase();
  List<String> get weekdayMini => ar ? const ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'] : const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  String month(int y, int m) => '${ar ? _ma[m - 1] : _ml[m - 1]} $y';

  String _relWord(DateTime d) {
    final k = DateTime.utc(d.year, d.month, d.day).difference(kToday).inDays;
    if (k == 0) return ar ? 'اليوم' : 'Today';
    if (k == 1) return ar ? 'غدًا' : 'Tomorrow';
    if (k == -1) return ar ? 'أمس' : 'Yesterday';
    return '';
  }

  String rel(DateTime d) {
    final w = _relWord(d);
    return w.isNotEmpty ? w : short(d);
  }

  String relLong(DateTime d) {
    final w = _relWord(d);
    return w.isNotEmpty ? w : mid(d);
  }

  String due(DateTime d) => '${ar ? 'يستحق' : 'Due'} ${short(d)}';

  /// '09:00' -> '09:00 AM' / '09:00 ص'
  String time(String? hm) {
    if (hm == null || hm.isEmpty) return '';
    final p = hm.split(':');
    final h = int.parse(p[0]);
    final h12 = h % 12 == 0 ? 12 : h % 12;
    final hh = h12.toString().padLeft(2, '0');
    final suffix = ar ? (h < 12 ? 'ص' : 'م') : (h < 12 ? 'AM' : 'PM');
    return '$hh:${p[1]} $suffix';
  }

  String _arN(int n, String one, String two, String few, String many) {
    final m = n % 100;
    final s = n == 1 ? one : n == 2 ? two : (n == 0 || (m >= 3 && m <= 10)) ? few : many;
    return s.replaceAll('#', '$n');
  }

  String nTasks(int n) => ar ? _arN(n, 'مهمة واحدة', 'مهمتان', '# مهام', '# مهمة') : '$n ${n == 1 ? 'task' : 'tasks'}';
  String nProjects(int n) =>
      ar ? _arN(n, 'مشروع واحد', 'مشروعان', '# مشاريع', '# مشروعًا') : '$n ${n == 1 ? 'project' : 'projects'}';
  String nActive(int n) => ar
      ? _arN(n, 'مهمة نشطة واحدة', 'مهمتان نشطتان', '# مهام نشطة', '# مهمة نشطة')
      : '$n ${n == 1 ? 'active task' : 'active tasks'}';
  String of(int a, int b) => ar ? '$a من $b مهام' : '$a of $b tasks';
  String subsOf(int a, int b) => ar ? '$a من $b مكتملة' : '$a of $b completed';
  String filtersOn(int n) => ar ? 'عوامل تصفية مطبّقة: $n' : '$n ${n == 1 ? 'filter' : 'filters'} applied';
  String showN(int n) => ar ? 'عرض ${nTasks(n)}' : 'Show ${nTasks(n)}';
}
