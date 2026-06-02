import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/auth/app_session.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/services/app_realtime.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_design.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../data/auth_api_service.dart';
import '../../data/role_mapper.dart';
import '../../domain/models/role.dart';
import '../../../patient_profile/data/patient_profile_repository.dart';
import '../../../patient_profile/presentation/widgets/medical_history_prompt_dialog.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authApi = AuthApiService();
  bool _obscureText = true;
  bool _loading = false;

  static const _featureItems = <({String label, IconData icon})>[
    (label: 'Citas', icon: Icons.calendar_month_rounded),
    (label: 'Emergencias', icon: Icons.emergency_rounded),
    (label: 'Resultados', icon: Icons.biotech_rounded),
    (label: 'Seguros', icon: Icons.verified_user_rounded),
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Ingresa correo y contraseña');
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await _authApi.login(email: email, password: password);
      _onAuthSuccess(response);
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(
        'No se pudo conectar al servidor (${ApiConfig.baseUrl}). Ejecuta: cd backend && pnpm run dev',
      );
      debugPrint('Login error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onAuthSuccess(AuthResponse response) async {
    AppSession.setSession(user: response.user, tokenValue: response.token);
    AppRealtime.reconnectAfterAuth();
    if (response.user.role == Role.patient) {
      await PatientProfileRepository.refreshFromApi();
    }
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      AppNavigation.homeRouteForRole(response.user.role),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  Future<void> _showRegisterDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Crear cuenta de paciente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Correo'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirmar contraseña'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Registrarse'),
          ),
        ],
      ),
    );

    if (created != true || !mounted) {
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
      passwordController.dispose();
      confirmController.dispose();
      return;
    }

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirm = confirmController.text;
    final phone = phoneController.text.trim();

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmController.dispose();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Completa nombre, correo y contraseña');
      return;
    }
    if (password != confirm) {
      _showError('Las contraseñas no coinciden');
      return;
    }
    if (password.length < 6) {
      _showError('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await _authApi.register(
        email: email,
        password: password,
        name: name,
        roleApi: RoleMapper.toApi(Role.patient),
        phone: phone.isEmpty ? null : phone,
      );
      AppSession.setSession(user: response.user, tokenValue: response.token);
      await PatientProfileRepository.refreshFromApi();
      if (!mounted) return;
      final fillHistory = await showMedicalHistoryPrompt(context);
      if (!mounted) return;
      if (fillHistory == true) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.clinicalHistory,
          arguments: {'onboarding': true},
        );
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      }
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('No se pudo conectar al servidor. Inicia el backend (pnpm run dev).');
      debugPrint('Register error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fillDemoCredentials(String email) {
    _emailController.text = email;
    _passwordController.text = 'password';
  }

  Future<void> _loginAsDemo(String email) async {
    _fillDemoCredentials(email);
    await _submitLogin();
  }

  void _enterMockRole(Role role, String route) {
    AppSession.clear();
    AppSession.setRole(role);
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 600;
    final isWide = width >= 860;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    if (isCompact) {
      return ResponsiveScaffold(
        hideNavigation: true,
        backgroundColor: const Color(0xFF1E3A8A),
        body: _buildMobileLogin(context, bottomInset),
      );
    }

    return ResponsiveScaffold(
      hideNavigation: true,
      backgroundColor: AppColors.background,
      body: AppPage(
        maxWidth: 1120,
        padding: EdgeInsets.fromLTRB(28, 28, 28, 28 + bottomInset),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _buildHero(context, isCompact: false)),
                  const SizedBox(width: 24),
                  SizedBox(
                    width: 430,
                    child: _buildLoginForm(context, isCompact: false),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHero(context, isCompact: false),
                const SizedBox(height: 20),
                _buildLoginForm(context, isCompact: false),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Login móvil a pantalla completa: gradiente, marca fuerte y formulario flotante.
  Widget _buildMobileLogin(BuildContext context, double bottomInset) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E40AF),
            Color(0xFF2563EB),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -80, right: -60, child: _decorCircle(220, 0.07)),
          Positioned(top: 120, left: -70, child: _decorCircle(160, 0.05)),
          Positioned(
            bottom: 180,
            right: -40,
            child: _decorCircle(120, 0.06),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMobileHeader(context),
                  const SizedBox(height: 24),
                  _buildMobileFormCard(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.55),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.favorite_rounded,
            color: Colors.white,
            size: 38,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'VITA OS',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
            height: 1,
            fontSize: 40,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tu salud, citas y emergencias\nen una sola plataforma.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.88),
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '¿Qué puedes hacer?',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.75),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.55,
          ),
          itemCount: _featureItems.length,
          itemBuilder: (context, i) => _mobileFeatureTile(_featureItems[i]),
        ),
      ],
    );
  }

  Widget _mobileFeatureTile(({String label, IconData icon}) item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(item.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFormCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.65),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 0,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
          child: _buildLoginFormFields(context, isCompact: true),
        ),
      ),
    );
  }

  Widget _buildHeroGradientShell({required Widget child}) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF3B82F6),
                  Color(0xFF2563EB),
                  Color(0xFF1E40AF),
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: -48,
          right: -32,
          child: _decorCircle(140, 0.10),
        ),
        Positioned(
          bottom: -24,
          left: -36,
          child: _decorCircle(100, 0.08),
        ),
        child,
      ],
    );
  }

  Widget _decorCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }

  Widget _buildHero(BuildContext context, {required bool isCompact}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: _buildHeroGradientShell(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: _buildHeroContent(context, isCompact: isCompact),
        ),
      ),
    );
  }

  Widget _buildHeroContent(BuildContext context, {required bool isCompact}) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: isCompact ? 52 : 64,
              height: isCompact ? 52 : 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(isCompact ? 16 : 22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
              ),
              child: Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: isCompact ? 28 : 34,
              ),
            ),
            if (isCompact) ...[
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VITA OS',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Salud conectada en un solo lugar',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        if (!isCompact) ...[
          const SizedBox(height: 28),
          Text(
            'VITA OS',
            style: theme.textTheme.displayLarge?.copyWith(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pacientes, médicos y administradores conectados a la base de datos.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
        ],
        SizedBox(height: isCompact ? 18 : 28),
        _buildFeatureGrid(isCompact: isCompact),
      ],
    );
  }

  Widget _buildFeatureGrid({required bool isCompact}) {
    if (isCompact) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.35,
        children: _featureItems.map(_heroFeatureChip).toList(),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _featureItems
          .map((f) => AppStatusPill(label: f.label, color: Colors.white, icon: f.icon))
          .toList(),
    );
  }

  Widget _heroFeatureChip(({String label, IconData icon}) item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              item.label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, {required bool isCompact}) {
    return AppPanel(
      padding: EdgeInsets.all(isCompact ? 20 : 28),
      child: _buildLoginFormFields(context, isCompact: isCompact),
    );
  }

  Widget _buildLoginFormFields(BuildContext context, {required bool isCompact}) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Accede a tu cuenta',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Inicia sesión o regístrate como paciente.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        SizedBox(height: isCompact ? 20 : 24),
        TextField(
          controller: _emailController,
          enabled: !_loading,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Correo electrónico',
            hintText: 'nombre@ejemplo.com',
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _passwordController,
          enabled: !_loading,
          obscureText: _obscureText,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitLogin(),
          decoration: InputDecoration(
            labelText: 'Contraseña',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
              ),
              onPressed: () => setState(() => _obscureText = !_obscureText),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: _loading
                ? null
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Recuperación de contraseña próximamente'),
                      ),
                    );
                  },
            child: const Text('Olvidé mi contraseña'),
          ),
        ),
        const SizedBox(height: 8),
        _buildPrimaryLoginButton(isCompact: isCompact),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _loading ? null : _showRegisterDialog,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
            label: const Text('Crear cuenta de paciente'),
          ),
        ),
        SizedBox(height: isCompact ? 12 : 16),
        _buildDemoSection(context, isCompact: isCompact),
      ],
    );
  }

  Widget _buildPrimaryLoginButton({required bool isCompact}) {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: _loading
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
          color: _loading ? AppColors.primary.withValues(alpha: 0.6) : null,
          boxShadow: _loading
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _loading ? null : _submitLogin,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoSection(BuildContext context, {required bool isCompact}) {
    final demoButtons = [
      _DemoEntry('Paciente', Icons.person_rounded, () => _loginAsDemo('juan@patient.com')),
      _DemoEntry('Médico', Icons.health_and_safety_rounded, () => _loginAsDemo('maria@doctor.com')),
      _DemoEntry('Jefe app', Icons.admin_panel_settings_rounded, () => _loginAsDemo('admin@vita.com')),
      _DemoEntry('Admin clínica', Icons.local_hospital_rounded, () => _loginAsDemo('clinic.admin@vita.com')),
      _DemoEntry('Admin farmacia', Icons.local_pharmacy_rounded, () => _loginAsDemo('pharmacy.admin@vita.com')),
      _DemoEntry('Farmacéutico', Icons.science_outlined, () => _loginAsDemo('farmacista@vita.com')),
      _DemoEntry(
        'Ambulancia',
        Icons.emergency_rounded,
        () => _enterMockRole(Role.driver, AppRoutes.ambulanceDashboard),
      ),
      _DemoEntry(
        'Farmacia',
        Icons.inventory_2_rounded,
        () => _enterMockRole(Role.pharmacy, AppRoutes.pharmacyAdmin),
      ),
      _DemoEntry(
        'Laboratorio',
        Icons.biotech_rounded,
        () => _loginAsDemo('lab@tech.com'),
      ),
    ];

    final chips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: demoButtons
          .map(
            (d) => _buildDemoButton(d.label, d.icon, d.onPressed, isCompact: isCompact),
          )
          .toList(),
    );

    if (!isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Cuentas de prueba (contraseña: password)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          chips,
        ],
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8, bottom: 4),
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          'Cuentas de prueba',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          'Contraseña: password',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        children: [chips],
      ),
    );
  }

  Widget _buildDemoButton(
    String label,
    IconData icon,
    VoidCallback onPressed, {
    required bool isCompact,
  }) {
    return OutlinedButton.icon(
      onPressed: _loading ? null : onPressed,
      style: isCompact
          ? OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(fontSize: 12),
            )
          : null,
      icon: Icon(icon, size: isCompact ? 18 : 24),
      label: Text(label),
    );
  }
}

class _DemoEntry {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _DemoEntry(this.label, this.icon, this.onPressed);
}
