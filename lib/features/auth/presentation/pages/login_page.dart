import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/branding/app_branding.dart';
import '../../../../core/auth/app_session.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/services/app_realtime.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/experience/animated_blobs.dart';
import '../../../../core/widgets/experience/fade_slide_in.dart';
import '../../../../core/widgets/promo/promo_carousel.dart';
import '../../../../core/widgets/promo/promo_models.dart';
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
    var navigatedAway = false;
    try {
      final response = await _authApi.login(email: email, password: password);
      navigatedAway = await _onAuthSuccess(response);
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(
        'No se pudo conectar al servidor (${ApiConfig.baseUrl}). Ejecuta: cd backend && pnpm run dev',
      );
      debugPrint('Login error: $e');
    } finally {
      if (mounted && !navigatedAway) setState(() => _loading = false);
    }
  }

  Future<bool> _onAuthSuccess(AuthResponse response) async {
    AppSession.setSession(user: response.user, tokenValue: response.token);
    AppRealtime.reconnectAfterAuth();
    if (response.user.role == Role.patient) {
      await PatientProfileRepository.refreshFromApi();
    }
    if (!mounted) return false;
    Navigator.pushReplacementNamed(
      context,
      AppNavigation.homeRouteForRole(response.user.role),
    );
    return true;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.emergency,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  Future<void> _showRegisterDialog() async {
    final form = await showDialog<_RegisterPatientForm>(
      context: context,
      builder: (ctx) => const _RegisterPatientDialog(),
    );

    if (form == null || !mounted) return;

    if (form.name.isEmpty || form.email.isEmpty || form.password.isEmpty) {
      _showError('Completa nombre, correo y contraseña');
      return;
    }
    if (form.password != form.confirmPassword) {
      _showError('Las contraseñas no coinciden');
      return;
    }
    if (form.password.length < 6) {
      _showError('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setState(() => _loading = true);
    var navigatedAway = false;
    try {
      final response = await _authApi.register(
        email: form.email,
        password: form.password,
        name: form.name,
        roleApi: RoleMapper.toApi(Role.patient),
        phone: form.phone.isEmpty ? null : form.phone,
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
      navigatedAway = true;
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('No se pudo conectar al servidor. Inicia el backend (pnpm run dev).');
      debugPrint('Register error: $e');
    } finally {
      if (mounted && !navigatedAway) setState(() => _loading = false);
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
    final isWide = width >= 900;

    return ResponsiveScaffold(
      hideNavigation: true,
      hideAppBar: true,
      body: AnimatedBlobsBackground(
        child: SafeArea(
          child: isWide ? _buildWideLayout(context) : _buildMobileLayout(context),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset),
      child: Column(
        children: [
          FadeSlideIn(child: _buildLogo()),
          const SizedBox(height: AppSpacing.lg),
          FadeSlideIn(
            index: 1,
            child: PromoCarousel(offers: PromoMockData.loginSlides),
          ),
          const SizedBox(height: AppSpacing.xxl),
          FadeSlideIn(index: 2, child: _buildFormCard(context, isCompact: true)),
        ],
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: FadeSlideIn(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogo(maxWidth: 480),
                      const SizedBox(height: AppSpacing.xxl),
                      PromoCarousel(offers: PromoMockData.loginSlides),
                      const SizedBox(height: AppSpacing.xxl),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: const [
                          _FeatureChip(label: 'Citas', icon: Icons.calendar_month_rounded),
                          _FeatureChip(label: 'Emergencias', icon: Icons.emergency_rounded),
                          _FeatureChip(label: 'Farmacia', icon: Icons.local_pharmacy_rounded),
                          _FeatureChip(label: 'Seguros', icon: Icons.shield_rounded),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 40),
              SizedBox(
                width: 420,
                child: FadeSlideIn(
                  index: 2,
                  offset: const Offset(0.08, 0),
                  child: _buildFormCard(context, isCompact: false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo({double maxWidth = 320}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const aspect = 1071 / 233;
        final width = (constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width)
            .clamp(0.0, maxWidth);
        return Image.asset(
          AppBranding.loginLogo,
          width: width,
          height: width / aspect,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        );
      },
    );
  }

  Widget _buildFormCard(BuildContext context, {required bool isCompact}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: EdgeInsets.all(isCompact ? 22 : 32),
      child: _buildFormFields(context, isCompact: isCompact),
    );
  }

  Widget _buildFormFields(BuildContext context, {required bool isCompact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Bienvenido de vuelta',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Inicia sesión o crea tu cuenta de paciente',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: isCompact ? 20 : 28),
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
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _loading
                ? null
                : () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Recuperación de contraseña próximamente'),
                    ),
                  ),
            child: const Text('Olvidé mi contraseña'),
          ),
        ),
        const SizedBox(height: 8),
        _GradientButton(
          label: 'Iniciar sesión',
          loading: _loading,
          onPressed: _submitLogin,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _loading ? null : _showRegisterDialog,
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
          label: const Text('Crear cuenta de paciente'),
        ),
        SizedBox(height: isCompact ? 16 : 20),
        _buildDemoSection(context, isCompact: isCompact),
      ],
    );
  }

  Widget _buildDemoSection(BuildContext context, {required bool isCompact}) {
    final demos = [
      _DemoEntry('Paciente', Icons.person_rounded, () => _loginAsDemo('juan@patient.com')),
      _DemoEntry('Médico', Icons.health_and_safety_rounded, () => _loginAsDemo('maria@doctor.com')),
      _DemoEntry('Admin', Icons.admin_panel_settings_rounded, () => _loginAsDemo('admin@vita.com')),
      _DemoEntry('Clínica', Icons.local_hospital_rounded, () => _loginAsDemo('clinic.admin@vita.com')),
      _DemoEntry('Farmacia', Icons.local_pharmacy_rounded, () => _loginAsDemo('pharmacy.admin@vita.com')),
      _DemoEntry('Lab', Icons.biotech_rounded, () => _loginAsDemo('lab@tech.com')),
      _DemoEntry('Ambulancia', Icons.emergency_rounded, () => _enterMockRole(Role.driver, AppRoutes.ambulanceDashboard)),
    ];

    final chips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: demos
          .map(
            (d) => ActionChip(
              avatar: Icon(d.icon, size: 16),
              label: Text(d.label),
              onPressed: _loading ? null : d.onPressed,
            ),
          )
          .toList(),
    );

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          'Cuentas de prueba',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: const Text(
          'Contraseña: password',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        children: [chips],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _FeatureChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _GradientButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: loading
              ? null
              : const LinearGradient(colors: AppColors.headerGradient),
          color: loading ? AppColors.primary.withValues(alpha: 0.5) : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: loading
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
            onTap: loading ? null : onPressed,
            borderRadius: BorderRadius.circular(AppRadius.md),
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
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
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

class _DemoEntry {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  const _DemoEntry(this.label, this.icon, this.onPressed);
}

class _RegisterPatientForm {
  const _RegisterPatientForm({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.confirmPassword,
  });
  final String name;
  final String email;
  final String phone;
  final String password;
  final String confirmPassword;
}

class _RegisterPatientDialog extends StatefulWidget {
  const _RegisterPatientDialog();
  @override
  State<_RegisterPatientDialog> createState() => _RegisterPatientDialogState();
}

class _RegisterPatientDialogState extends State<_RegisterPatientDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.pop(
      context,
      _RegisterPatientForm(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.headerGradient,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(Icons.person_add_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Crear cuenta',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Correo'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirmar contraseña'),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _submit,
                      child: const Text('Registrarse'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
