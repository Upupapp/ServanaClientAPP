import 'package:client/common/constants/color_palette.dart';
import 'package:client/common/constants/font_palette.dart';
import 'package:flutter/material.dart';

// ── Section ────────────────────────────────────────────────────────────────

class SettingsSectionHeader extends StatelessWidget {
  final String title;
  const SettingsSectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontFamily: FontPalette.primaryFontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.8,
          color: ColorPalette.accentText.withOpacity(.7),
        ),
      ),
    );
  }
}

class SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const SettingsGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: ColorPalette.secondaryBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ColorPalette.border(.35)),
        ),
        child: Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 52,
                  color: ColorPalette.border(.3),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Navigation tile (chevron) ──────────────────────────────────────────────

class SettingsNavTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final String? trailingValue;
  final VoidCallback onTap;

  const SettingsNavTile({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.trailingValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = iconColor ?? ColorPalette.primaryColorDark;
    return Semantics(
      button: true,
      label: title,
      hint: subtitle,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 20, color: accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: ColorPalette.secondaryText,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          fontSize: 12,
                          color: ColorPalette.accentText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingValue != null) ...[
                const SizedBox(width: 8),
                Text(
                  trailingValue!,
                  style: TextStyle(
                    fontFamily: FontPalette.primaryFontFamily,
                    fontSize: 13,
                    color: ColorPalette.accentText,
                  ),
                ),
              ],
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: ColorPalette.accentText.withOpacity(.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Toggle tile ────────────────────────────────────────────────────────────

class SettingsToggleTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final bool saving;
  final ValueChanged<bool> onChanged;

  const SettingsToggleTile({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    this.saving = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = iconColor ?? ColorPalette.primaryColorDark;
    return Semantics(
      toggled: value,
      label: title,
      hint: subtitle,
      // excludeSemantics prevents the inner Switch from generating a duplicate
      // accessibility node — only the outer Semantics fires for screen readers.
      excludeSemantics: true,
      onTap: saving ? null : () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: accent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: ColorPalette.secondaryText,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontSize: 12,
                        color: ColorPalette.accentText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (saving)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: ColorPalette.primaryColorDark,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Value tile (read-only) ─────────────────────────────────────────────────

class SettingsValueTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const SettingsValueTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 20, color: ColorPalette.primaryColorDark),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: FontPalette.primaryFontFamily,
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: ColorPalette.secondaryText,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: FontPalette.primaryFontFamily,
              fontSize: 13,
              color: ColorPalette.accentText,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Unavailable tile ───────────────────────────────────────────────────────

class SettingsUnavailableTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String reason;

  const SettingsUnavailableTile({
    super.key,
    required this.icon,
    required this.title,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title — $reason',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon,
                size: 20, color: ColorPalette.accentText.withOpacity(.5)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: ColorPalette.secondaryText.withOpacity(.45),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reason,
                    style: TextStyle(
                      fontFamily: FontPalette.primaryFontFamily,
                      fontSize: 12,
                      color: ColorPalette.accentText.withOpacity(.55),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: ColorPalette.border(.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Soon',
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.accentText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Destructive tile ───────────────────────────────────────────────────────

class SettingsDestructiveTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const SettingsDestructiveTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: ColorPalette.danger),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: ColorPalette.danger,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Permission tile ────────────────────────────────────────────────────────

enum PermissionStatus {
  allowed,
  denied,
  restricted,
  notDetermined,
  unavailable
}

class SettingsPermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? purpose;
  final PermissionStatus status;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onRequest;

  const SettingsPermissionTile({
    super.key,
    required this.icon,
    required this.title,
    this.purpose,
    required this.status,
    this.onOpenSettings,
    this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final (label, labelColor) = switch (status) {
      PermissionStatus.allowed => ('Allowed', const Color(0xFF16A34A)),
      PermissionStatus.denied => ('Denied', ColorPalette.danger),
      PermissionStatus.restricted => ('Restricted', ColorPalette.danger),
      PermissionStatus.notDetermined => ('Not set', ColorPalette.accentText),
      PermissionStatus.unavailable => ('Unavailable', ColorPalette.accentText),
    };
    final canOpenSettings = (status == PermissionStatus.denied ||
            status == PermissionStatus.restricted) &&
        onOpenSettings != null;
    final canRequest =
        status == PermissionStatus.notDetermined && onRequest != null;
    final effectiveTap = canOpenSettings
        ? onOpenSettings
        : canRequest
            ? onRequest
            : null;

    return Semantics(
      label: '$title — $label',
      button: effectiveTap != null,
      child: InkWell(
        onTap: effectiveTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 20, color: ColorPalette.primaryColorDark),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: FontPalette.primaryFontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: ColorPalette.secondaryText,
                      ),
                    ),
                    if (purpose != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        purpose!,
                        style: TextStyle(
                          fontFamily: FontPalette.primaryFontFamily,
                          fontSize: 12,
                          color: ColorPalette.accentText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: FontPalette.primaryFontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
              if (canOpenSettings) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 14,
                  color: ColorPalette.accentText.withOpacity(.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
