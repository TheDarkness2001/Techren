import 'package:flutter/material.dart';

import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../feedback/screens/daily_feedback_screen.dart';
import '../../attendance/screens/teacher_attendance_screen.dart';

export '../../attendance/screens/staff_teacher_attendance_screen.dart';

class StaffStudentAttendanceScreen extends StatelessWidget {
  const StaffStudentAttendanceScreen({
    super.key,
    required this.navItems,
    required this.selectedRoute,
  });

  final List<NavItem> navItems;
  final String selectedRoute;

  @override
  Widget build(BuildContext context) {
    return TeacherAttendancePage(
      navItems: navItems,
      selectedRoute: selectedRoute,
    );
  }
}

class StaffFeedbackScreen extends StatelessWidget {
  const StaffFeedbackScreen({
    super.key,
    required this.navItems,
    required this.selectedRoute,
  });

  final List<NavItem> navItems;
  final String selectedRoute;

  @override
  Widget build(BuildContext context) {
    return DailyFeedbackScreen(
      navItems: navItems,
      selectedRoute: selectedRoute,
    );
  }
}
