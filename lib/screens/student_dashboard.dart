// lib/screens/student_dashboard.dart
// Redesigned Achivo Student Dashboard — persistent sidebar, modern cards

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_models.dart';
import '../services/student_service.dart';
import 'leave_application_page.dart';
import 'documents_page.dart';
import 'student_attendance_page.dart';
import 'student_marks_page.dart';
import 'student_fee_dashboard.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────

class AchivoColors {
  static const purple       = Color(0xFF7F77DD);
  static const purpleDark   = Color(0xFF534AB7);
  static const purpleLight  = Color(0xFFEEEDFE);
  static const teal         = Color(0xFF1D9E75);
  static const tealDark     = Color(0xFF0F6E56);
  static const tealLight    = Color(0xFFE1F5EE);
  static const amber        = Color(0xFFBA7517);
  static const amberLight   = Color(0xFFFAEEDA);
  static const red          = Color(0xFFE24B4A);
  static const redLight     = Color(0xFFFCEBEB);
  static const surface      = Color(0xFFF8FAFC);
  static const cardBg       = Colors.white;
  static const border       = Color(0xFFE8EAF0);
  static const textPrimary  = Color(0xFF1A1D23);
  static const textSecond   = Color(0xFF6B7280);
  static const textHint     = Color(0xFF9CA3AF);

  static const gradientMain = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [purple, purpleDark, teal],
  );
  static const gradientTeal = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [teal, tealDark],
  );
  static const gradientPurple = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [purpleDark, Color(0xFF3C3489)],
  );
  static const gradientAmber = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [amber, Color(0xFF854F0B)],
  );
  static const gradientGreen = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF3B6D11), Color(0xFF27500A)],
  );
}

// ── Nav item model ────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String   label;
  final int      index;
  final int?     badge;
  const _NavItem(this.icon, this.label, this.index, {this.badge});
}

// ═════════════════════════════════════════════════════════════════════════════
// ROOT DASHBOARD
// ═════════════════════════════════════════════════════════════════════════════

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({Key? key}) : super(key: key);
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int              _selectedIndex = 0;
  StudentProfile?  _studentProfile;
  DashboardStats?  _dashboardStats;
  bool             _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    setState(() => _isLoading = true);
    try {
      await StudentService.ensureStorageBuckets();
      final profile = await StudentService.getCurrentStudentProfile();
      if (profile != null) {
        final stats = await StudentService.getDashboardStats(profile.id);
        if (mounted) setState(() { _studentProfile = profile; _dashboardStats = stats; _isLoading = false; });
      } else {
        if (mounted) { setState(() => _isLoading = false); _showError('Could not load student profile.'); }
      }
    } catch (e) {
      if (mounted) { setState(() => _isLoading = false); _showError('Failed to load dashboard data'); }
    }
  }

  void _showError(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));

  Future<void> _handleSignOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/welcome', (r) => false);
    } catch (e) { _showError('Error signing out'); }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: AchivoColors.surface, body: Center(child: CircularProgressIndicator(color: AchivoColors.purple)));

    if (_studentProfile == null) return _ErrorScreen(onRetry: _loadStudentData);

    final bool wide = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      backgroundColor: AchivoColors.surface,
      drawer: wide ? null : _buildDrawer(),
      appBar: wide ? null : _buildMobileAppBar(),
      body: wide ? _buildWideLayout() : _buildBody(),
    );
  }

  // ── Wide layout (tablet/desktop): sidebar + content ──────────────────────

  Widget _buildWideLayout() {
    return Row(
      children: [
        _buildSidebar(),
        const VerticalDivider(width: 1, color: AchivoColors.border),
        Expanded(child: _buildBody()),
      ],
    );
  }

  // ── Persistent sidebar (wide screens) ────────────────────────────────────

  Widget _buildSidebar() {
    return Container(
      width: 230,
      color: AchivoColors.cardBg,
      child: Column(
        children: [
          _buildSidebarHeader(),
          Expanded(child: _buildNavList()),
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AchivoColors.border, width: 0.5))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(gradient: AchivoColors.gradientMain, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Achivo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AchivoColors.textPrimary)),
            Text('Student Portal', style: TextStyle(fontSize: 11, color: AchivoColors.textSecond)),
          ]),
        ]),
        const SizedBox(height: 14),
        _buildStudentPill(compact: true),
      ]),
    );
  }

  Widget _buildStudentPill({bool compact = false}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AchivoColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AchivoColors.border),
      ),
      child: Row(children: [
        _AvatarCircle(initials: _studentProfile!.firstName.substring(0, 1).toUpperCase(), size: 34),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_studentProfile!.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AchivoColors.textPrimary), overflow: TextOverflow.ellipsis),
          Text('${_studentProfile!.rollNumber} · Year ${_studentProfile!.displayYear}',
              style: const TextStyle(fontSize: 11, color: AchivoColors.textSecond), overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }

  Widget _buildNavList() {
    final mainItems = [
      const _NavItem(Icons.dashboard_rounded,        'Overview',          0),
      const _NavItem(Icons.how_to_reg_rounded,        'Attendance',        1),
      const _NavItem(Icons.workspace_premium_rounded, 'Marks',             2),
    ];
    final serviceItems = [
      _NavItem(Icons.event_busy_rounded,              'Leave Applications', 3, badge: (_dashboardStats?.pendingLeaves ?? 0) > 0 ? _dashboardStats!.pendingLeaves : null),
      const _NavItem(Icons.folder_rounded,            'Documents',         4),
      const _NavItem(Icons.account_balance_wallet_rounded, 'Fee Payment',  5),
      const _NavItem(Icons.emoji_events_rounded,      'Credit Activities', 6),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _navSection('Main'),
          ...mainItems.map(_buildNavTile),
          const SizedBox(height: 4),
          _navSection('Services'),
          ...serviceItems.map(_buildNavTile),
        ],
      ),
    );
  }

  Widget _navSection(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
    child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AchivoColors.textHint, letterSpacing: 0.8)),
  );

  Widget _buildNavTile(_NavItem item) {
    final bool active = _selectedIndex == item.index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: active ? AchivoColors.purpleLight : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: active ? AchivoColors.purple.withOpacity(0.3) : Colors.transparent),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _selectedIndex = item.index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(children: [
            Icon(item.icon, size: 18, color: active ? AchivoColors.purpleDark : AchivoColors.textSecond),
            const SizedBox(width: 10),
            Expanded(child: Text(item.label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active ? AchivoColors.purpleDark : AchivoColors.textSecond))),
            if (item.badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AchivoColors.redLight, borderRadius: BorderRadius.circular(10)),
                child: Text('${item.badge}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AchivoColors.red)),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AchivoColors.border, width: 0.5))),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _handleSignOut,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(children: [
            const Icon(Icons.logout_rounded, size: 18, color: AchivoColors.textSecond),
            const SizedBox(width: 10),
            const Text('Sign out', style: TextStyle(fontSize: 13, color: AchivoColors.textSecond)),
          ]),
        ),
      ),
    );
  }

  // ── Mobile appbar + drawer ────────────────────────────────────────────────

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AchivoColors.cardBg,
      foregroundColor: AchivoColors.textPrimary,
      titleSpacing: 0,
      title: Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(gradient: AchivoColors.gradientMain, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.school_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('Achivo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          Text(_getPageTitle(), style: const TextStyle(fontSize: 11, color: AchivoColors.textSecond)),
        ]),
      ]),
      actions: [
        Stack(clipBehavior: Clip.none, children: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          Positioned(top: 10, right: 10, child: Container(width: 7, height: 7,
              decoration: const BoxDecoration(color: AchivoColors.red, shape: BoxShape.circle))),
        ]),
        Padding(padding: const EdgeInsets.only(right: 12),
            child: _AvatarCircle(initials: _studentProfile!.firstName.substring(0, 1), size: 34)),
      ],
      bottom: PreferredSize(preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AchivoColors.border)),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: _buildStudentPill()),
        const Divider(height: 1, color: AchivoColors.border),
        Expanded(child: _buildNavList()),
        const Divider(height: 1, color: AchivoColors.border),
        _buildSidebarFooter(),
      ])),
    );
  }

  // ── Page body ─────────────────────────────────────────────────────────────

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: return OverviewPage(student: _studentProfile!, stats: _dashboardStats!, onRefresh: _loadStudentData, onNavigate: (i) => setState(() => _selectedIndex = i));
      case 1: return StudentAttendancePage(studentId: _studentProfile!.id);
      case 2: return StudentMarksPage(studentId: _studentProfile!.id);
      case 3: return LeaveApplicationPage(studentId: _studentProfile!.id);
      case 4: return DocumentsPage(studentId: _studentProfile!.id);
      case 5: return StudentFeeDashboard(studentId: _studentProfile!.id);
      case 6: return CreditActivitiesPage(studentId: _studentProfile!.id);
      default: return OverviewPage(student: _studentProfile!, stats: _dashboardStats!, onRefresh: _loadStudentData, onNavigate: (i) => setState(() => _selectedIndex = i));
    }
  }

  String _getPageTitle() {
    const titles = ['Overview', 'Attendance', 'Marks', 'Leave', 'Documents', 'Fees', 'Credits'];
    return titles[_selectedIndex.clamp(0, titles.length - 1)];
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// OVERVIEW PAGE
// ═════════════════════════════════════════════════════════════════════════════

class OverviewPage extends StatelessWidget {
  final StudentProfile student;
  final DashboardStats stats;
  final VoidCallback   onRefresh;
  final ValueChanged<int> onNavigate;

  const OverviewPage({Key? key, required this.student, required this.stats, required this.onRefresh, required this.onNavigate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AchivoColors.purple,
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _WelcomeBanner(student: student),
          const SizedBox(height: 20),
          _StatsRow(stats: stats),
          const SizedBox(height: 20),
          _QuickActions(student: student, onNavigate: onNavigate),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }
}

// ── Welcome banner ────────────────────────────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  final StudentProfile student;
  const _WelcomeBanner({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AchivoColors.gradientMain,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(children: [
        // Decorative circles
        Positioned(right: -10, top: -20,
            child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)))),
        Positioned(right: 40, bottom: -30,
            child: Container(width: 70, height: 70, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.04)))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Welcome back, ${student.firstName}! 🎓',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text("Here's your academic snapshot", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 6, children: [
            _WelcomeChip(Icons.calendar_today_rounded, 'Semester 5'),
            _WelcomeChip(Icons.business_rounded, 'Computer Science'),
            _WelcomeChip(Icons.star_rounded, '2025–26'),
          ]),
        ]),
      ]),
    );
  }
}

class _WelcomeChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _WelcomeChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white70, size: 13),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ]),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final DashboardStats stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final att = stats.attendancePercentage;
    final credits = stats.totalCredits == 0 ? 0 : ((stats.creditsCompleted / stats.totalCredits) * 100).toInt();

    return Column(children: [
      Row(children: [
        Expanded(child: _StatCard(icon: Icons.book_rounded, iconBg: AchivoColors.purpleLight, iconColor: AchivoColors.purpleDark,
            value: stats.cgpa?.toStringAsFixed(2) ?? '—', label: 'Current CGPA',
            sub: stats.cgpa != null ? (stats.cgpa! >= 8.0 ? '↑ Great standing' : 'Keep improving') : 'Not updated',
            subColor: AchivoColors.purpleDark, progress: stats.cgpa != null ? stats.cgpa! / 10.0 : null, progressColor: AchivoColors.purple)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(icon: Icons.how_to_reg_rounded, iconBg: AchivoColors.tealLight, iconColor: AchivoColors.tealDark,
            value: '${att.toInt()}%', label: 'Attendance',
            sub: att >= 75 ? '✓ Above 75% threshold' : '⚠ Below 75% threshold',
            subColor: att >= 75 ? AchivoColors.tealDark : AchivoColors.red,
            progress: att / 100, progressColor: att >= 75 ? AchivoColors.teal : AchivoColors.red)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _StatCard(icon: Icons.emoji_events_rounded, iconBg: AchivoColors.amberLight, iconColor: AchivoColors.amber,
            value: '${stats.creditsCompleted}/${stats.totalCredits}', label: 'Credits Earned',
            sub: '$credits% completed', subColor: AchivoColors.amber,
            progress: stats.totalCredits == 0 ? 0 : stats.creditsCompleted / stats.totalCredits, progressColor: AchivoColors.amber)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(icon: Icons.pending_actions_rounded, iconBg: AchivoColors.redLight, iconColor: AchivoColors.red,
            value: '${stats.pendingLeaves}', label: 'Pending Leaves',
            sub: stats.pendingLeaves == 0 ? 'No pending leaves' : 'Awaiting approval',
            subColor: stats.pendingLeaves > 0 ? AchivoColors.red : AchivoColors.textHint)),
      ]),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color    iconBg, iconColor;
  final String   value, label, sub;
  final Color    subColor;
  final double?  progress;
  final Color?   progressColor;

  const _StatCard({required this.icon, required this.iconBg, required this.iconColor,
    required this.value, required this.label, required this.sub, required this.subColor,
    this.progress, this.progressColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AchivoColors.cardBg, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AchivoColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 18)),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AchivoColors.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AchivoColors.textSecond)),
        const SizedBox(height: 4),
        Text(sub, style: TextStyle(fontSize: 11, color: subColor), maxLines: 1, overflow: TextOverflow.ellipsis),
        if (progress != null) ...[
          const SizedBox(height: 10),
          ClipRRect(borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: progress!.clamp(0.0, 1.0), minHeight: 5,
                  backgroundColor: iconBg, valueColor: AlwaysStoppedAnimation<Color>(progressColor!))),
        ],
      ]),
    );
  }
}

// ── Quick actions ─────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final StudentProfile    student;
  final ValueChanged<int> onNavigate;
  const _QuickActions({required this.student, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.how_to_reg_rounded,                'Attendance',       AchivoColors.teal,     1),
      (Icons.workspace_premium_rounded,          'Marks',            AchivoColors.purpleDark, 2),
      (Icons.event_busy_rounded,                 'Apply Leave',      AchivoColors.amber,    3),
      (Icons.upload_file_rounded,                'Documents',        AchivoColors.purple,   4),
      (Icons.account_balance_wallet_rounded,     'Fee Payment',      AchivoColors.tealDark, 5),
      (Icons.emoji_events_rounded,               'Activities',       AchivoColors.red,      6),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AchivoColors.cardBg, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AchivoColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.bolt_rounded, color: AchivoColors.amber, size: 18),
          const SizedBox(width: 6),
          const Text('Quick Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AchivoColors.textPrimary)),
        ]),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3, childAspectRatio: 1.1, crossAxisSpacing: 10, mainAxisSpacing: 10,
          children: actions.map((a) => _ActionTile(
            icon: a.$1 as IconData, label: a.$2 as String,
            color: a.$3 as Color,
            onTap: () => onNavigate(a.$4 as int),
          )).toList(),
        ),
      ]),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

class _AvatarCircle extends StatelessWidget {
  final String initials;
  final double size;
  const _AvatarCircle({required this.initials, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AchivoColors.gradientMain),
      child: Center(child: Text(initials.toUpperCase(), style: TextStyle(color: Colors.white, fontSize: size * 0.35, fontWeight: FontWeight.bold))),
    );
  }
}

// ── Section header (reusable banner for sub-pages) ────────────────────────────

class AchivoPageBanner extends StatelessWidget {
  final String       title;
  final String       subtitle;
  final Gradient     gradient;
  final List<Widget> chips;

  const AchivoPageBanner({Key? key, required this.title, required this.subtitle, required this.gradient, this.chips = const []}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        if (chips.isNotEmpty) ...[const SizedBox(height: 10), Wrap(spacing: 8, runSpacing: 6, children: chips)],
      ]),
    );
  }
}

class AchivoStatusBadge extends StatelessWidget {
  final String status;
  const AchivoStatusBadge(this.status, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (status.toLowerCase()) {
      case 'approved': case 'paid': case 'verified': bg = AchivoColors.tealLight; fg = AchivoColors.tealDark; break;
      case 'pending':  bg = AchivoColors.amberLight; fg = AchivoColors.amber; break;
      case 'rejected': case 'failed': case 'overdue': bg = AchivoColors.redLight; fg = AchivoColors.red; break;
      default: bg = const Color(0xFFF1EFE8); fg = const Color(0xFF5F5E5A);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: fg.withOpacity(0.3))),
      child: Text(status[0].toUpperCase() + status.substring(1), style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Error screen ──────────────────────────────────────────────────────────────

class _ErrorScreen extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorScreen({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AchivoColors.surface,
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AchivoColors.redLight, shape: BoxShape.circle),
            child: const Icon(Icons.error_outline_rounded, size: 48, color: AchivoColors.red)),
        const SizedBox(height: 20),
        const Text('Failed to load profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AchivoColors.textPrimary)),
        const SizedBox(height: 8),
        const Text('Please check your connection', style: TextStyle(color: AchivoColors.textSecond)),
        const SizedBox(height: 24),
        FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry'),
            style: FilledButton.styleFrom(backgroundColor: AchivoColors.purple, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12))),
      ])),
    );
  }
}

// ── Credit activities placeholder ─────────────────────────────────────────────

class CreditActivitiesPage extends StatelessWidget {
  final String studentId;
  const CreditActivitiesPage({Key? key, required this.studentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const AchivoPageBanner(title: 'Credit Activities', subtitle: '85 / 150 credits earned', gradient: AchivoColors.gradientAmber),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(color: AchivoColors.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AchivoColors.border)),
          child: Column(children: [
            Icon(Icons.emoji_events_rounded, size: 56, color: AchivoColors.textHint.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text('Credit Activities — Coming Soon', style: TextStyle(fontSize: 15, color: AchivoColors.textSecond)),
          ]),
        ),
      ]),
    );
  }
}