import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_design.dart';

/// Chip de estadística sobre el header con gradiente (estilo login VITA OS).
class ProfileStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ProfileStatChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Header de perfil con gradiente oscuro–azul (misma línea visual que el login).
class ProfileGradientHeader extends StatelessWidget {
  final String name;
  final String? subtitle;
  final String badgeLabel;
  final IconData badgeIcon;
  final Color badgeColor;
  final Widget? leading;
  final List<ProfileStatChip> stats;
  final List<Widget>? actions;

  const ProfileGradientHeader({
    super.key,
    required this.name,
    this.subtitle,
    required this.badgeLabel,
    this.badgeIcon = Icons.verified_rounded,
    this.badgeColor = Colors.white,
    this.leading,
    this.stats = const [],
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isCompact ? 24 : 28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E40AF),
            Color(0xFF2563EB),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(top: -40, right: -30, child: _orb(120)),
          Positioned(bottom: -20, left: -24, child: _orb(90)),
          Padding(
            padding: EdgeInsets.all(isCompact ? 18 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final actionWidgets = actions ?? const <Widget>[];
                    final titleBlock = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _badge(),
                        const SizedBox(height: 14),
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                height: 1.1,
                              ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            subtitle!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.88),
                                ),
                          ),
                        ],
                      ],
                    );

                    final stackActionsBelow =
                        constraints.maxWidth < 360 && actionWidgets.isNotEmpty;

                    if (stackActionsBelow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (leading != null) ...[
                                leading!,
                                const SizedBox(width: 14),
                              ],
                              Expanded(child: titleBlock),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: actionWidgets,
                            ),
                          ),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (leading != null) ...[
                          leading!,
                          const SizedBox(width: 14),
                        ],
                        Expanded(child: titleBlock),
                        ...actionWidgets,
                      ],
                    );
                  },
                ),
                if (stats.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, c) {
                      if (c.maxWidth < 400) {
                        return Column(
                          children: [
                            for (var i = 0; i < stats.length; i++) ...[
                              if (i > 0) const SizedBox(height: 8),
                              stats[i],
                            ],
                          ],
                        );
                      }
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: stats
                            .map(
                              (s) => SizedBox(
                                width: (c.maxWidth - 8) / 2,
                                child: s,
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: badgeColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, color: badgeColor, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              badgeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orb(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.07),
      ),
    );
  }
}

/// Botón circular del header (notificaciones, cerrar sesión, etc.).
class ProfileHeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool onDarkBackground;

  const ProfileHeaderIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.onDarkBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        fixedSize: const Size(44, 44),
        minimumSize: const Size(44, 44),
        padding: EdgeInsets.zero,
        shape: const CircleBorder(),
        foregroundColor: onDarkBackground ? Colors.white : AppColors.primaryDark,
        backgroundColor: onDarkBackground
            ? Colors.white.withValues(alpha: 0.16)
            : AppColors.primaryLight,
      ),
      icon: Icon(icon, size: 22),
    );
  }
}

/// Tarjeta blanca de sección para datos del perfil.
class ProfileSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  const ProfileSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const ProfileInfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner de aviso (historia incompleta, etc.).
class ProfileAlertBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const ProfileAlertBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.color = AppColors.warning,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
              if (onTap != null) Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón principal con gradiente (login / perfil).
class ProfileGradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;

  const ProfileGradientButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: loading
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
          color: loading ? AppColors.primary.withValues(alpha: 0.5) : null,
          boxShadow: loading
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: loading ? null : onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Contenedor estándar para pantallas de perfil (scroll, refresh, ancho máximo).
class ProfileScreenLayout extends StatelessWidget {
  final bool loading;
  final Future<void> Function()? onRefresh;
  final double maxWidth;
  final List<Widget> children;

  const ProfileScreenLayout({
    super.key,
    this.loading = false,
    this.onRefresh,
    this.maxWidth = 680,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isCompact = MediaQuery.sizeOf(context).width < 600;
    final page = AppPage(
      maxWidth: maxWidth,
      padding: EdgeInsets.fromLTRB(
        isCompact ? 16 : 24,
        isCompact ? 8 : 16,
        isCompact ? 16 : 24,
        32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );

    if (onRefresh == null) return page;

    return RefreshIndicator(
      onRefresh: onRefresh!,
      child: page,
    );
  }
}

/// Cerrar sesión con el mismo estilo en todos los perfiles.
class ProfileLogoutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ProfileLogoutButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.logout_rounded),
      label: const Text('Cerrar sesión'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        foregroundColor: AppColors.emergency,
        side: BorderSide(color: AppColors.emergency.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
