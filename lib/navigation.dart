import 'package:flutter/material.dart';

import 'screens/project_detail_screen.dart';
import 'screens/space_detail_screen.dart';
import 'screens/task_detail_screen.dart';

/// Page transition: quick fade + small slide (≈220ms), direction-aware.
Route<T> fbRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 240),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (context, anim, _, child) {
        final rtl = Directionality.of(context) == TextDirection.rtl;
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: Offset(rtl ? -0.06 : 0.06, 0), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );

Future<T?> push<T>(BuildContext context, Widget page) => Navigator.of(context).push<T>(fbRoute<T>(page));

Future<T?> replace<T>(BuildContext context, Widget page) =>
    Navigator.of(context).pushReplacement<T, Object?>(fbRoute<T>(page));

void openTask(BuildContext context, String id) => push(context, TaskDetailScreen(taskId: id));
void openProject(BuildContext context, String id) => push(context, ProjectDetailScreen(projectId: id));
void openSpace(BuildContext context, String id) => push(context, SpaceDetailScreen(spaceId: id));
