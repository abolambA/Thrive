import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../utils/app_theme.dart';
import '../services/database_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _allergy = TextEditingController();
  final _emergency = TextEditingController();
  final _examSub = TextEditingController();

  bool _examMode = false;
  DateTime? _examDate;
  String _blood = 'Unknown';
  int _total = 0;
  int _streak = 0;
  final _bloods = ['Unknown', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() { super.initState(); _loadAll(); }

  Future<void> _loadAll() async {
    final p = await SharedPreferences.getInstance();
    final total = await DatabaseService.instance.getCheckInCount();
    final streak = await DatabaseService.instance.getStreak();
    if (mounted) setState(() {
      _name.text = p.getString('user_name') ?? '';
      _allergy.text = p.getString('allergies') ?? '';
      _emergency.text = p.getString('emergency_contact') ?? '';
      _blood = p.getString('blood_type') ?? 'Unknown';
      _examMode = p.getBool('exam_mode') ?? false;
      _examSub.text = p.getString('exam_subject') ?? '';
      final d = p.getString('exam_date');
      if (d != null) _examDate = DateTime.tryParse(d);
      _total = total;
      _streak = streak;
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('user_name', _name.text);
    await p.setString('allergies', _allergy.text);
    await p.setString('emergency_contact', _emergency.text);
    await p.setString('blood_type', _blood);
    await p.setBool('exam_mode', _examMode);
    await p.setString('exam_subject', _examSub.text);
    if (_examDate != null) await p.setString('exam_date', _examDate!.toIso8601String());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Profile saved ✓', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  @override
  void dispose() {
    _name.dispose(); _allergy.dispose(); _emergency.dispose(); _examSub.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 20),
            FadeInDown(child: const Text('Profile',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.text, letterSpacing: -1))),
            const SizedBox(height: 24),

            // Stats
            FadeInUp(delay: const Duration(milliseconds: 100), child: Row(children: [
              _stat('$_total', 'Check-ins', Icons.check_circle_rounded, AppTheme.primary),
              const SizedBox(width: 12),
              _stat('$_streak', 'Day Streak', Icons.local_fire_department_rounded, AppTheme.coral),
              const SizedBox(width: 12),
              _stat(_blood == 'Unknown' ? '—' : _blood, 'Blood', Icons.bloodtype_rounded, AppTheme.danger),
            ])),
            const SizedBox(height: 24),

            FadeInUp(delay: const Duration(milliseconds: 150), child: _section('Personal Information')),
            const SizedBox(height: 12),
            FadeInUp(delay: const Duration(milliseconds: 175), child: _field(_name, 'Your Name', Icons.person_rounded)),
            const SizedBox(height: 24),

            // Emergency Card
            FadeInUp(delay: const Duration(milliseconds: 200), child: _section('Emergency Card')),
            const SizedBox(height: 4),
            FadeInUp(delay: const Duration(milliseconds: 210),
                child: const Text('Quick-access info for emergencies',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMut))),
            const SizedBox(height: 12),
            FadeInUp(delay: const Duration(milliseconds: 250), child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(color: AppTheme.danger.withValues(alpha: 0.25),
                      blurRadius: 16, offset: const Offset(0, 6))
                ],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.emergency_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('EMERGENCY CARD',
                      style: TextStyle(color: Colors.white, fontSize: 13,
                          fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  Spacer(),
                  Icon(Icons.credit_card_rounded, color: Colors.white54, size: 18),
                ]),
                const SizedBox(height: 20),
                _emergRow('Name', _name.text.isEmpty ? '—' : _name.text),
                _emergRow('Blood Type', _blood == 'Unknown' ? '—' : _blood),
                _emergRow('Allergies', _allergy.text.isEmpty ? 'None listed' : _allergy.text),
                _emergRow('Emergency', _emergency.text.isEmpty ? '—' : _emergency.text),
              ]),
            )),
            const SizedBox(height: 16),

            // Blood type
            FadeInUp(delay: const Duration(milliseconds: 300), child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _blood, isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items: _bloods.map((t) => DropdownMenuItem(
                      value: t, child: Text('Blood Type: $t',
                      style: const TextStyle(fontSize: 14)))).toList(),
                  onChanged: (v) => setState(() => _blood = v!),
                ),
              ),
            )),
            const SizedBox(height: 12),
            FadeInUp(delay: const Duration(milliseconds: 320), child: _field(_allergy, 'Allergies (optional)', Icons.warning_amber_rounded)),
            const SizedBox(height: 12),
            FadeInUp(delay: const Duration(milliseconds: 340), child: _field(_emergency, 'Emergency Contact (phone)', Icons.phone_rounded)),
            const SizedBox(height: 24),

            // Exam Mode
            FadeInUp(delay: const Duration(milliseconds: 400), child: _section('Exam Mode')),
            const SizedBox(height: 12),
            FadeInUp(delay: const Duration(milliseconds: 430), child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _examMode ? AppTheme.amber.withValues(alpha: 0.5) : AppTheme.border,
                    width: _examMode ? 2 : 1),
              ),
              child: Column(children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                        color: AppTheme.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.school_rounded, color: AppTheme.amber, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Exam Mode',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.text)),
                    Text('AI optimizes advice for exam prep',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMut)),
                  ])),
                  Switch.adaptive(
                      value: _examMode, activeColor: AppTheme.amber,
                      onChanged: (v) => setState(() => _examMode = v)),
                ]),
                if (_examMode) ...[
                  const SizedBox(height: 16),
                  _field(_examSub, 'Exam Subject', Icons.book_rounded),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _examDate ?? DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 120)),
                      );
                      if (d != null) setState(() => _examDate = d);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
                      child: Row(children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.textSec),
                        const SizedBox(width: 12),
                        Text(
                          _examDate != null
                              ? DateFormat('EEEE, MMM d').format(_examDate!)
                              : 'Set exam date',
                          style: TextStyle(
                              fontSize: 14,
                              color: _examDate != null ? AppTheme.text : AppTheme.textMut,
                              fontWeight: _examDate != null ? FontWeight.w600 : FontWeight.w400),
                        ),
                        if (_examDate != null) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: AppTheme.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              '${_examDate!.difference(DateTime.now()).inDays}d left',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.amber),
                            ),
                          ),
                        ],
                      ]),
                    ),
                  ),
                ],
              ]),
            )),
            const SizedBox(height: 32),

            FadeInUp(delay: const Duration(milliseconds: 500), child: SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Save Profile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            )),
            const SizedBox(height: 24),

            FadeInUp(delay: const Duration(milliseconds: 560), child: Center(
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: AppTheme.surface, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.favorite_rounded, size: 14, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Text('Thrive v1.0',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSec, fontWeight: FontWeight.w600)),
                  ]),
                ),
                const SizedBox(height: 8),
                Text('Built for AUS Computing Competition',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMut)),
              ]),
            )),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  Widget _stat(String v, String l, IconData ic, Color c) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Icon(ic, color: c, size: 22),
        const SizedBox(height: 6),
        Text(v, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c)),
        const SizedBox(height: 2),
        Text(l, style: TextStyle(fontSize: 10, color: AppTheme.textSec)),
      ]),
    ),
  );

  Widget _section(String t) => Text(t,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.text));

  Widget _field(TextEditingController c, String h, IconData ic) => TextField(
    controller: c,
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.text),
    decoration: InputDecoration(
      hintText: h,
      prefixIcon: Icon(ic, size: 18, color: AppTheme.textMut),
    ),
  );

  Widget _emergRow(String l, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      SizedBox(width: 90,
          child: Text(l, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500))),
      Expanded(child: Text(v,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
    ]),
  );
}
