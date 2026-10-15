import '../core/tokens.dart';
import 'models.dart';

/// All dates are UTC calendar days so day math never drifts with daylight saving.
DateTime _d(int m, int day) => DateTime.utc(2026, m, day);

List<Space> mockSpaces() => [
      Space(
        id: 'work',
        name: const LText('Work', 'العمل'),
        icon: 'briefcase',
        tone: Tone.indigo,
        description: const LText('A place for professional projects and responsibilities.', 'مكان للمشاريع والمسؤوليات المهنية.'),
      ),
      Space(
        id: 'study',
        name: const LText('Study', 'الدراسة'),
        icon: 'book',
        tone: Tone.green,
        description: const LText('Courses, research, and everything you are learning.', 'المقررات والأبحاث وكل ما تتعلّمه.'),
      ),
      Space(
        id: 'personal',
        name: const LText('Personal', 'الشخصي'),
        icon: 'user',
        tone: Tone.amber,
        description: const LText('Personal goals, side projects, and life admin.', 'الأهداف الشخصية والمشاريع الجانبية وشؤون الحياة.'),
      ),
      Space(
        id: 'health',
        name: const LText('Health', 'الصحة'),
        icon: 'activity',
        tone: Tone.rose,
        description: const LText('Training, nutrition, and healthy routines.', 'التمارين والتغذية والعادات الصحية.'),
      ),
    ];

List<Project> mockProjects() => [
      Project(id: 'mobile', spaceId: 'work', name: const LText('Mobile App Redesign', 'إعادة تصميم تطبيق الجوال'), due: _d(10, 30), icon: 'phone',
          notes: const LText('Redesign the mobile experience with a cleaner, faster workflow.', 'إعادة تصميم تجربة الجوال بسير عمل أوضح وأسرع.')),
      Project(id: 'web', spaceId: 'work', name: const LText('Website Redesign', 'إعادة تصميم الموقع'), due: _d(11, 15), icon: 'monitor',
          notes: const LText('Refresh the marketing site structure, copy, and analytics.', 'تحديث هيكل الموقع التسويقي ومحتواه وتحليلاته.')),
      Project(id: 'q4', spaceId: 'work', name: const LText('Q4 Planning', 'تخطيط الربع الرابع'), due: _d(11, 20), icon: 'target',
          notes: const LText('Set goals, budget, and priorities for the last quarter.', 'تحديد الأهداف والميزانية والأولويات للربع الأخير.')),
      Project(id: 'ai', spaceId: 'study', name: const LText('AI Research Paper', 'ورقة بحثية في الذكاء الاصطناعي'), due: _d(11, 12), icon: 'note',
          notes: const LText('A research paper on training efficiency in neural networks.', 'ورقة بحثية حول كفاءة تدريب الشبكات العصبية.')),
      Project(id: 'dl', spaceId: 'study', name: const LText('Deep Learning Course', 'مقرر التعلّم العميق'), due: _d(12, 10), icon: 'book',
          notes: const LText('Weekly lectures, quizzes, and the final CNN project.', 'المحاضرات الأسبوعية والاختبارات القصيرة ومشروع الشبكات الالتفافية النهائي.')),
      Project(id: 'portfolio', spaceId: 'personal', name: const LText('Portfolio Website', 'موقع الأعمال الشخصي'), due: _d(11, 30), icon: 'star',
          notes: const LText('Showcase recent work with two new case studies.', 'عرض الأعمال الأخيرة مع دراستي حالة جديدتين.')),
      Project(id: 'office', spaceId: 'personal', name: const LText('Home Office Setup', 'تجهيز المكتب المنزلي'), due: _d(11, 20), icon: 'home',
          notes: const LText('A calm, comfortable place to work from home.', 'مساحة هادئة ومريحة للعمل من المنزل.')),
      Project(id: 'fitness', spaceId: 'health', name: const LText('Fitness Program', 'برنامج اللياقة'), due: _d(12, 31), icon: 'activity',
          notes: const LText('Three workouts a week and better meal planning.', 'ثلاثة تمارين أسبوعيًا وتخطيط أفضل للوجبات.')),
    ];

const _projectSpace = {
  'mobile': 'work', 'web': 'work', 'q4': 'work', 'ai': 'study', 'dl': 'study',
  'portfolio': 'personal', 'office': 'personal', 'fitness': 'health',
};

const _p = Priority.values;
const _todo = TaskStatus.todo, _prog = TaskStatus.inProgress, _done = TaskStatus.done;

Task _t(String id, String en, String ar, String project, DateTime date, String? time, Priority pr, TaskStatus st) => Task(
      id: id,
      title: LText(en, ar),
      spaceId: _projectSpace[project]!,
      projectId: project,
      date: date,
      time: time,
      priority: pr,
      status: st,
    );

List<Task> mockTasks() {
  final low = _p[0], med = _p[1], high = _p[2], urgent = _p[3];
  final tasks = <Task>[
    _t('t1', 'Review Flutter documentation', 'مراجعة توثيق Flutter', 'mobile', _d(10, 26), '09:00', med, _prog),
    _t('t2', 'Finalize onboarding flow', 'إنهاء تدفق التهيئة', 'mobile', _d(10, 26), '10:30', high, _todo),
    _t('t3', 'Review UI components', 'مراجعة مكونات الواجهة', 'mobile', _d(10, 27), '13:00', med, _todo),
    _t('t4', 'Connect navigation states', 'ربط حالات التنقل', 'mobile', _d(10, 28), null, low, _todo),
    _t('t5', 'Prepare release checklist', 'إعداد قائمة الإطلاق', 'mobile', _d(10, 30), null, med, _todo),
    _t('t6', 'Audit current app flows', 'تدقيق تدفقات التطبيق الحالية', 'mobile', _d(10, 12), null, med, _done),
    _t('t7', 'Map user journeys', 'رسم رحلات المستخدم', 'mobile', _d(10, 13), null, med, _done),
    _t('t8', 'Define color tokens', 'تحديد رموز الألوان', 'mobile', _d(10, 15), null, low, _done),
    _t('t9', 'Set up type scale', 'إعداد مقياس الخطوط', 'mobile', _d(10, 16), null, low, _done),
    _t('t10', 'Wireframe home screen', 'رسم الهيكل الأولي للشاشة الرئيسية', 'mobile', _d(10, 19), null, high, _done),
    _t('t11', 'Design icon set', 'تصميم مجموعة الأيقونات', 'mobile', _d(10, 20), null, med, _done),
    _t('t12', 'Build component library', 'بناء مكتبة المكونات', 'mobile', _d(10, 21), null, high, _done),
    _t('t13', 'Run usability test round 1', 'إجراء اختبار قابلية الاستخدام الأول', 'mobile', _d(10, 22), null, high, _done),
    _t('t14', 'Stakeholder design review', 'مراجعة التصميم مع أصحاب المصلحة', 'mobile', _d(10, 23), null, med, _done),
    _t('t15', 'Review API design', 'مراجعة تصميم واجهة البرمجة', 'web', _d(10, 27), '10:00', med, _todo),
    _t('t16', 'Draft new sitemap', 'إعداد خريطة الموقع الجديدة', 'web', _d(10, 29), null, high, _todo),
    _t('t17', 'Write homepage copy', 'كتابة نصوص الصفحة الرئيسية', 'web', _d(11, 2), null, med, _todo),
    _t('t18', 'Set up analytics events', 'إعداد أحداث التحليلات', 'web', _d(11, 5), null, low, _todo),
    _t('t19', 'Plan content migration', 'تخطيط نقل المحتوى', 'web', _d(11, 9), null, med, _todo),
    _t('t20', 'Collect analytics baseline', 'جمع بيانات التحليلات الأساسية', 'web', _d(10, 14), null, low, _done),
    _t('t21', 'Review competitor sites', 'مراجعة مواقع المنافسين', 'web', _d(10, 16), null, med, _done),
    _t('t22', 'Write kickoff notes', 'كتابة ملاحظات الاجتماع الافتتاحي', 'web', _d(10, 20), null, low, _done),
    _t('t23', 'Prepare project presentation', 'إعداد عرض المشروع', 'q4', _d(10, 26), '14:00', high, _todo),
    _t('t24', 'Finalize Q4 budget', 'اعتماد ميزانية الربع الرابع', 'q4', _d(10, 29), null, urgent, _todo),
    _t('t25', 'Review Q3 results', 'مراجعة نتائج الربع الثالث', 'q4', _d(10, 5), null, high, _done),
    _t('t26', 'Collect team goals', 'جمع أهداف الفريق', 'q4', _d(10, 7), null, med, _done),
    _t('t27', 'Draft OKRs', 'صياغة الأهداف والنتائج الرئيسية', 'q4', _d(10, 9), null, high, _done),
    _t('t28', 'Plan hiring needs', 'تخطيط احتياجات التوظيف', 'q4', _d(10, 14), null, med, _done),
    _t('t29', 'Align with leadership', 'التنسيق مع الإدارة', 'q4', _d(10, 19), null, high, _done),
    _t('t30', 'Update roadmap', 'تحديث خارطة الطريق', 'q4', _d(10, 21), null, med, _done),
    _t('t31', 'Book planning offsite', 'حجز لقاء التخطيط الخارجي', 'q4', _d(10, 23), null, low, _done),
    _t('t32', 'Share Q3 retro notes', 'مشاركة ملاحظات مراجعة الربع الثالث', 'q4', _d(10, 26), '08:30', low, _done),
    _t('t33', 'Finish Deep Learning assignment', 'إنهاء واجب التعلّم العميق', 'ai', _d(10, 26), '11:30', high, _prog),
    _t('t34', 'Submit research draft', 'تسليم مسودة البحث', 'ai', _d(10, 27), '15:30', high, _todo),
    _t('t35', 'Run baseline experiments', 'تشغيل التجارب الأساسية', 'ai', _d(10, 29), null, med, _todo),
    _t('t36', 'Complete literature review', 'إكمال مراجعة الأدبيات', 'ai', _d(10, 15), null, high, _done),
    _t('t37', 'Define research question', 'تحديد سؤال البحث', 'ai', _d(10, 8), null, med, _done),
    _t('t38', 'Watch lecture 7: CNNs', 'مشاهدة المحاضرة 7: الشبكات الالتفافية', 'dl', _d(10, 28), '19:00', med, _todo),
    _t('t39', 'Read chapter 4', 'قراءة الفصل الرابع', 'dl', _d(10, 30), null, low, _todo),
    _t('t40', 'Review backpropagation notes', 'مراجعة ملاحظات الانتشار العكسي', 'dl', _d(10, 31), null, low, _todo),
    _t('t41', 'Prepare for quiz 3', 'الاستعداد للاختبار القصير 3', 'dl', _d(11, 2), null, med, _todo),
    _t('t42', 'Prepare final Deep Learning project presentation and documentation', 'إعداد العرض النهائي لمشروع التعلّم العميق وتوثيقه', 'dl', _d(11, 9), null, high, _todo),
    _t('t43', 'Summarize lecture 6', 'تلخيص المحاضرة 6', 'dl', _d(10, 21), null, low, _done),
    _t('t44', 'Complete quiz 2', 'إكمال الاختبار القصير 2', 'dl', _d(10, 19), null, med, _done),
    _t('t45', 'Update portfolio', 'تحديث ملف الأعمال', 'portfolio', _d(10, 28), '18:00', med, _todo),
    _t('t46', 'Write FlowBase case study', 'كتابة دراسة حالة FlowBase', 'portfolio', _d(11, 3), null, med, _todo),
    _t('t47', 'Refresh profile photo', 'تحديث الصورة الشخصية', 'portfolio', _d(11, 6), null, low, _todo),
    _t('t48', 'Pick a domain name', 'اختيار اسم النطاق', 'portfolio', _d(10, 17), null, low, _done),
    _t('t49', 'Order standing desk', 'طلب مكتب قابل للوقوف', 'office', _d(10, 30), null, low, _todo),
    _t('t50', 'Install monitor arm', 'تركيب حامل الشاشة', 'office', _d(11, 7), null, low, _todo),
    _t('t51', 'Measure the room', 'قياس الغرفة', 'office', _d(10, 18), null, low, _done),
    _t('t52', 'Choose a desk chair', 'اختيار كرسي المكتب', 'office', _d(10, 22), null, med, _done),
    _t('t53', 'Workout session', 'جلسة تمرين', 'fitness', _d(10, 26), '17:00', low, _todo),
    _t('t54', 'Evening run — 5 km', 'جري مسائي — 5 كم', 'fitness', _d(10, 28), '19:30', med, _todo),
    _t('t55', 'Meal prep for the week', 'تحضير وجبات الأسبوع', 'fitness', _d(11, 1), null, low, _todo),
    _t('t56', 'Book gym assessment', 'حجز تقييم النادي الرياضي', 'fitness', _d(10, 20), null, med, _done),
    _t('t57', 'Morning yoga', 'يوغا صباحية', 'fitness', _d(10, 26), '07:00', low, _done),
  ];

  Task byId(String id) => tasks.firstWhere((t) => t.id == id);

  byId('t33')
    ..description = const LText('Complete the remaining exercises and review the neural networks section before submission.',
        'أكمل التمارين المتبقية وراجع قسم الشبكات العصبية قبل التسليم.')
    ..notes = const LText('Upload the notebook and the PDF report to the course portal.', 'ارفع دفتر الملاحظات وتقرير PDF إلى بوابة المقرر.')
    ..subtasks = [
      SubTask(id: 's1', title: const LText('Review lecture notes', 'مراجعة ملاحظات المحاضرة'), done: true),
      SubTask(id: 's2', title: const LText('Complete exercise 1', 'إكمال التمرين 1'), done: true),
      SubTask(id: 's3', title: const LText('Complete exercise 2', 'إكمال التمرين 2')),
      SubTask(id: 's4', title: const LText('Review answers', 'مراجعة الإجابات')),
    ];
  byId('t2')
    ..description = const LText('Polish the first-run experience from the welcome screen to the first created task.',
        'تحسين تجربة الاستخدام الأولى من شاشة الترحيب حتى إنشاء أول مهمة.')
    ..subtasks = [
      SubTask(id: 's5', title: const LText('Welcome screen', 'شاشة الترحيب'), done: true),
      SubTask(id: 's6', title: const LText('Sign-in states', 'حالات تسجيل الدخول')),
      SubTask(id: 's7', title: const LText('Empty states', 'الحالات الفارغة')),
    ];
  byId('t1').description =
      const LText('Go through the latest docs on navigation and state management.', 'مراجعة أحدث التوثيق الخاص بالتنقل وإدارة الحالة.');
  byId('t23').description = const LText('Walk the team through Q4 goals, budget, and the mobile redesign timeline.',
      'عرض أهداف الربع الرابع والميزانية والجدول الزمني لإعادة تصميم التطبيق على الفريق.');
  return tasks;
}
