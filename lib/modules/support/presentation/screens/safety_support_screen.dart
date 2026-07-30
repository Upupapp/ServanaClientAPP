import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:client/common/injectors/main_injector.dart';
import 'package:client/core/analytics/application/analytics_coordinator.dart';
import 'package:client/core/analytics/events/support_events.dart';
import 'package:client/modules/support/data/support_repository.dart';
import 'package:client/modules/support/domain/safety_incident.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SafetySupportScreen extends StatefulWidget {
  const SafetySupportScreen({super.key});

  static const String route = '/support/safety';
  static const String routeName = 'SupportSafety';

  @override
  State<SafetySupportScreen> createState() => _SafetySupportScreenState();
}

class _SafetySupportScreenState extends State<SafetySupportScreen> {
  List<EmergencyLine>? _emergencyLines;
  bool _showReportForm = false;

  void _track(dynamic event) {
    try {
      dpLocator<AnalyticsCoordinator>().track(event).ignore();
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _track(const SafetyEntryOpenedEvent());
    _loadEmergency();
  }

  Future<void> _loadEmergency() async {
    try {
      final repo = dpLocator<SupportRepository>();
      final lines = await repo.getEmergencyConfig();
      if (mounted) setState(() => _emergencyLines = lines);
    } catch (_) {
      if (mounted) {
        setState(() {
          _emergencyLines = const [
            EmergencyLine(
              label: 'Emergency Hotline',
              dialLabel: '911',
              number: '911',
              description: 'Police, Fire, Medical',
            ),
            EmergencyLine(
              label: 'National Emergency Hotline',
              dialLabel: '117',
              number: '117',
              description: 'NDRRMC 24/7',
            ),
            EmergencyLine(
              label: 'Red Cross',
              dialLabel: '143',
              number: '143',
              description: 'Philippine Red Cross',
            ),
          ];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.primaryBackground,
      appBar: AppBar(
        backgroundColor: ColorPalette.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: ColorPalette.secondaryText),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: Text(
          'Safety & Emergency',
          style: TextStyle(
            fontFamily: FontPalette.primaryFontFamily,
            fontWeight: FontWeight.w700,
            color: ColorPalette.secondaryText,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emergency_outlined,
                        color: Color(0xFFDC2626), size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'In Immediate Danger?',
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Call emergency services immediately. Do not wait — your safety comes first.',
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 13,
                    color: const Color(0xFF7F1D1D),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                if (_emergencyLines == null)
                  const Center(child: CircularProgressIndicator())
                else
                  ..._emergencyLines!.map(
                    (line) => _EmergencyCallButton(line: line),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 20),
          Text(
            'Report a Safety Concern',
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ColorPalette.secondaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Not an emergency, but something felt wrong? Let us know and Servana will follow up.',
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontSize: 13,
              color: ColorPalette.accentText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          if (_showReportForm)
            _SafetyReportForm(
              onClose: () => setState(() => _showReportForm = false),
              onSubmitted: () {
                setState(() => _showReportForm = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Your safety report has been submitted. Servana will review it.',
                      style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily),
                    ),
                    backgroundColor: ColorPalette.primaryColorDark,
                  ),
                );
              },
            )
          else
            ElevatedButton.icon(
              onPressed: () => setState(() => _showReportForm = true),
              icon: const Icon(Icons.report_outlined),
              label: const Text('Submit a Safety Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.primaryColorDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ColorPalette.secondaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColorPalette.border(.15)),
            ),
            child: Text(
              'All safety reports are reviewed by the Servana Trust & Safety team within 24 hours. '
              'Serious incidents are escalated immediately.',
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontSize: 12,
                color: ColorPalette.accentText,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyCallButton extends StatelessWidget {
  const _EmergencyCallButton({required this.line});
  final EmergencyLine line;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Call ${line.label}: ${line.dialLabel}',
      child: InkWell(
        onTap: () async {
          final uri = Uri(scheme: 'tel', path: line.number);
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.phone_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.label,
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (line.description.isNotEmpty)
                      Text(
                        line.description,
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                line.dialLabel,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SafetyReportForm extends StatefulWidget {
  const _SafetyReportForm({
    required this.onClose,
    required this.onSubmitted,
  });
  final VoidCallback onClose;
  final VoidCallback onSubmitted;

  @override
  State<_SafetyReportForm> createState() => _SafetyReportFormState();
}

class _SafetyReportFormState extends State<_SafetyReportForm> {
  SafetyIncidentSeverity _severity = SafetyIncidentSeverity.general;
  SafetyIncidentCategory _category = SafetyIncidentCategory.other;
  final _descCtrl = TextEditingController();
  String? _error;
  bool _submitting = false;

  void _track(dynamic event) {
    try {
      dpLocator<AnalyticsCoordinator>().track(event).ignore();
    } catch (_) {}
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final desc = _descCtrl.text.trim();
    if (desc.length < 10) {
      setState(() =>
          _error = 'Please describe what happened in at least a few words.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    _track(const SafetySubmissionAttemptedEvent());
    try {
      final repo = dpLocator<SupportRepository>();
      final clientIncidentId =
          'ci-${DateTime.now().millisecondsSinceEpoch}-${_category.apiKey}';
      await repo.submitSafetyIncident(
        clientIncidentId: clientIncidentId,
        severity: _severity,
        category: _category,
        description: desc,
      );
      if (!mounted) return;
      _track(const SafetySubmissionSucceededEvent());
      widget.onSubmitted();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Could not submit the report. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorPalette.secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColorPalette.border(.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Safety Report',
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ColorPalette.secondaryText,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: ColorPalette.accentText),
                onPressed: widget.onClose,
                tooltip: 'Cancel',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _label('How serious was this?'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: SafetyIncidentSeverity.values
                .where((s) => s != SafetyIncidentSeverity.immediateDanger)
                .map((s) {
              final sel = _severity == s;
              return Semantics(
                button: true,
                selected: sel,
                label: s.label,
                child: InkWell(
                  onTap: () => setState(() => _severity = s),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    constraints: const BoxConstraints(minHeight: 44),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel
                        ? ColorPalette.primaryColorDark
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel
                          ? ColorPalette.primaryColorDark
                          : ColorPalette.border(.35),
                    ),
                  ),
                  child: Text(
                    s.label,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : ColorPalette.accentText,
                    ),
                  ),
                ),
              ),
            );
            }).toList(),
          ),
          const SizedBox(height: 14),
          _label('What type of incident?'),
          const SizedBox(height: 6),
          DropdownButtonFormField<SafetyIncidentCategory>(
            value: _category,
            onChanged: (v) {
              if (v != null) setState(() => _category = v);
            },
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontSize: 13,
              color: ColorPalette.secondaryText,
            ),
            decoration: _inputDecoration('Select incident type'),
            items: SafetyIncidentCategory.values.map((c) {
              return DropdownMenuItem(
                value: c,
                child: Text(c.label),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          _label('Describe what happened'),
          const SizedBox(height: 6),
          TextField(
            controller: _descCtrl,
            minLines: 4,
            maxLines: 8,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontSize: 13,
              color: ColorPalette.secondaryText,
            ),
            decoration: _inputDecoration(
                'Describe what happened, when, and where…'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontSize: 12,
                color: ColorPalette.danger,
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.primaryColorDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit Report'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: TextStyle(
          fontFamily: FontPalette.primaryFontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: ColorPalette.secondaryText,
        ),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: FontPalette.primaryFontFamily,
          fontSize: 13,
          color: ColorPalette.accentText.withOpacity(.5),
        ),
        filled: true,
        fillColor: ColorPalette.primaryBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: ColorPalette.border(.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: ColorPalette.border(.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: ColorPalette.primaryColorDark, width: 1.5),
        ),
      );
}
