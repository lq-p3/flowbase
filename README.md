# FlowBase — Flutter

**Powerful inside. Simple outside.**

واجهة FlowBase كاملة بـ Flutter: 17 شاشة، وضع فاتح وداكن، عربي (RTL) وإنجليزي، وبيانات تجريبية محلية.
لا يوجد Backend ولا قاعدة بيانات ولا تسجيل دخول حقيقي — كل شيء يعمل من الذاكرة.

## التشغيل

تحتاج Flutter 3.22 أو أحدث.

```bash
cd flowbase
flutter create . --project-name flowbase --platforms android,ios,web
flutter pub get
flutter run
```

الأمر `flutter create .` يولّد فقط مجلدات المنصات (android / ios / web) ولا يغيّر ملفات `lib/`.

- للتجربة على المتصفح: `flutter run -d chrome` — يظهر التطبيق بحجم جوال (393×852) في منتصف الشاشة.
- للاختبارات: `flutter test`

## بنية المشروع

```
lib/
  main.dart                 التطبيق + معاينة بحجم الجوال على الشاشات العريضة
  navigation.dart           الانتقالات بين الشاشات
  core/
    tokens.dart             الألوان (فاتح/داكن) والمسافات والزوايا والخطوط
    theme.dart              ThemeData
    strings.dart            النصوص بالعربي والإنجليزي
    format.dart             التواريخ والأوقات والجمع بالعربي
    context_ext.dart        اختصارات: context.fb / context.s / context.app
  data/
    models.dart             Space · Project · Task · SubTask · TaskFilters
    mock_data.dart          البيانات التجريبية (4 مساحات، 8 مشاريع، 57 مهمة)
  state/app_state.dart      الحالة المحلية (ChangeNotifier)
  widgets/                  المكونات المشتركة
    controls.dart           الأزرار، الحقول، الشرائح، الشارات، مربع الاختيار...
    cards.dart              TaskCard · ProjectCard · SpaceCard
    layout.dart             الترويسات، الحالات الفارغة، الأخطاء، هياكل التحميل
    overlays.dart           النوافذ السفلية، الفلاتر، التأكيد، الرسائل المنبثقة
    bottom_nav.dart         شريط التنقل السفلي
  screens/                  كل الشاشات
assets/fonts/               Inter و IBM Plex Sans Arabic (رخصة OFL)
```

## ما يعمل في النموذج

- إنشاء المهام وتعديلها وحذفها وإكمالها، وإضافة مهام فرعية.
- إنشاء المساحات والمشاريع وحذفها.
- البحث، والفلاتر، وتبويبات المهام، واختيار الأيام في التقويم.
- تبديل السمة (فاتح / داكن / النظام) واللغة (English / العربية) من الإعدادات.
- كل الأرقام محسوبة من نفس البيانات، فأي تغيير يظهر في كل الشاشات.
- في وضع التطوير (debug) يوجد في الإعدادات › أخرى صف **"حالات التصميم"** لعرض حالات التحميل والفراغ والأخطاء.

## ملاحظات

- "اليوم" في النموذج هو الإثنين 26 أكتوبر 2026 (ثابت في `kToday`).
- الأيقونات من Material Icons (نمط Outlined/Rounded) لتجنّب أي حزمة إضافية.
- لتغيير الألوان عدّل `lib/core/tokens.dart` فقط.
