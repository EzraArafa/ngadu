import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

/// S-02 Auth Screen (Masuk & Daftar akun).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  int _selectedTab = 0; // 0 = Masuk, 1 = Daftar

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();

  bool _obscureLogin = true;
  bool _obscureRegister = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (_selectedTab == index || _isLoading) return;
    setState(() {
      _selectedTab = index;
      _errorMessage = null;
    });
  }

  String _formatAuthError(Object error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        return 'Email atau kata sandi yang Anda masukkan salah.';
      }
      if (msg.contains('email not confirmed')) {
        return 'Email belum diverifikasi. Silakan periksa kotak masuk email Anda.';
      }
      if (msg.contains('user already registered')) {
        return 'Email ini sudah terdaftar. Silakan masuk menggunakan akun tersebut.';
      }
      if (msg.contains('password should be at least')) {
        return 'Kata sandi minimal harus terdiri dari 6 karakter.';
      }
      return error.message;
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _handleLogin() async {
    final email = _loginEmailController.text.trim();
    final pass = _loginPasswordController.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _errorMessage = 'Email dan kata sandi wajib diisi.');
      return;
    }

    if (!SupabaseService.isConfigured) {
      setState(() {
        _errorMessage = 'Supabase URL/Anon Key belum di-set di build flags.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService.signIn(email, pass);
      final profile = await SupabaseService.fetchCurrentUser();
      if (!mounted) return;

      if (profile != null) {
        context.read<AuthController>().setUser(profile);
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _errorMessage =
              'Data profil pengguna tidak ditemukan. Hubungi admin kampus.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = _formatAuthError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    final name = _registerNameController.text.trim();
    final email = _registerEmailController.text.trim();
    final pass = _registerPasswordController.text;
    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      setState(() => _errorMessage = 'Seluruh kolom pendaftaran wajib diisi.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _errorMessage = 'Kata sandi minimal harus 6 karakter.');
      return;
    }

    if (!SupabaseService.isConfigured) {
      setState(() {
        _errorMessage = 'Supabase belum terkonfigurasi. Cek --dart-define.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService.signUp(name, email, pass);
      final profile = await SupabaseService.fetchCurrentUser();
      if (!mounted) return;

      if (profile != null) {
        context.read<AuthController>().setUser(profile);
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Terjadi jika Supabase mewajibkan konfirmasi email terlebih dahulu
        setState(() {
          _selectedTab = 0;
          _loginEmailController.text = email;
          _errorMessage =
              'Pendaftaran berhasil. Silakan cek email untuk verifikasi lalu masuk.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = _formatAuthError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xxl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Identitas Aplikasi
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.report_problem_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'NGADU',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Laporkan & pantau perbaikan fasilitas kampus',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Kartu Form Utama
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Segmented Tab Switcher
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(AppRadius.input),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _SegmentButton(
                                  label: 'Masuk',
                                  selected: _selectedTab == 0,
                                  onTap: () => _switchTab(0),
                                ),
                              ),
                              Expanded(
                                child: _SegmentButton(
                                  label: 'Daftar',
                                  selected: _selectedTab == 1,
                                  onTap: () => _switchTab(1),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Banner Pesan Error / Info
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.dangerBg,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.input),
                              border: Border.all(
                                color: AppColors.dangerBorder,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 18,
                                  color: AppColors.dangerText,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.dangerText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        // Form Dinamis (tanpa tinggi kaku)
                        if (_selectedTab == 0)
                          _buildLoginForm()
                        else
                          _buildRegisterForm(),
                      ],
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

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _loginEmailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'Email Kampus / Pribadi',
            hintText: 'nama@kampus.ac.id',
            prefixIcon: Icon(Icons.email_outlined, size: 20),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _loginPasswordController,
          obscureText: _obscureLogin,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => _isLoading ? null : _handleLogin(),
          decoration: InputDecoration(
            labelText: 'Kata Sandi',
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureLogin
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureLogin = !_obscureLogin),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: _isLoading ? null : _handleLogin,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : const Text('Masuk ke Akun'),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _registerNameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          decoration: const InputDecoration(
            labelText: 'Nama Lengkap',
            hintText: 'Masukkan nama lengkap',
            prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _registerEmailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'Email Kampus / Pribadi',
            hintText: 'nama@kampus.ac.id',
            prefixIcon: Icon(Icons.email_outlined, size: 20),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _registerPasswordController,
          obscureText: _obscureRegister,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          onSubmitted: (_) => _isLoading ? null : _handleRegister(),
          decoration: InputDecoration(
            labelText: 'Kata Sandi',
            hintText: 'Minimal 6 karakter',
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureRegister
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscureRegister = !_obscureRegister),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: _isLoading ? null : _handleRegister,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : const Text('Daftar Akun Baru'),
        ),
      ],
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.badge),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}