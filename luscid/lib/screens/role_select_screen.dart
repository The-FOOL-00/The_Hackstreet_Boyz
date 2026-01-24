/// Role selection screen for first-time users
///
/// Allows users to select their role (Senior or Caregiver) and create PIN.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/numeric_keypad.dart';
import '../widgets/loading_overlay.dart';
import 'home_screen.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  UserRole? _selectedRole;
  String _pin = '';
  String _confirmPin = '';
  bool _isCreatingPin = false;
  bool _isConfirmingPin = false;
  String? _error;

  void _selectRole(UserRole role) {
    setState(() {
      _selectedRole = role;
      _isCreatingPin = true;
    });
  }

  void _onDigitPressed(String digit) {
    if (_isConfirmingPin) {
      if (_confirmPin.length < 4) {
        setState(() {
          _confirmPin += digit;
          _error = null;
        });
        if (_confirmPin.length == 4) {
          _createAccount();
        }
      }
    } else {
      if (_pin.length < 4) {
        setState(() {
          _pin += digit;
          _error = null;
        });
        if (_pin.length == 4) {
          setState(() {
            _isConfirmingPin = true;
          });
        }
      }
    }
  }

  void _onBackspace() {
    if (_isConfirmingPin) {
      if (_confirmPin.isNotEmpty) {
        setState(() {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
          _error = null;
        });
      } else {
        setState(() {
          _isConfirmingPin = false;
        });
      }
    } else {
      if (_pin.isNotEmpty) {
        setState(() {
          _pin = _pin.substring(0, _pin.length - 1);
          _error = null;
        });
      }
    }
  }

  void _onClear() {
    setState(() {
      if (_isConfirmingPin) {
        _confirmPin = '';
      } else {
        _pin = '';
      }
      _error = null;
    });
  }

  Future<void> _createAccount() async {
    if (_pin != _confirmPin) {
      setState(() {
        _error = 'PINs do not match. Please try again.';
        _confirmPin = '';
      });
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.createAccount(
      pin: _pin,
      role: _selectedRole!,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      setState(() {
        _error = authProvider.error ?? 'Failed to create account';
        _confirmPin = '';
      });
    }
  }

  void _goBack() {
    setState(() {
      if (_isConfirmingPin) {
        _isConfirmingPin = false;
        _confirmPin = '';
      } else if (_isCreatingPin) {
        _isCreatingPin = false;
        _pin = '';
      }
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return LoadingOverlay(
          isLoading: authProvider.isLoading,
          message: 'Creating your account...',
          child: Scaffold(
            backgroundColor: AppColors.backgroundBeige,
            appBar: _isCreatingPin
                ? AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: _goBack,
                    ),
                  )
                : null,
            body: SafeArea(
              child: _isCreatingPin
                  ? _buildPinCreation()
                  : _buildRoleSelection(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleSelection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Center(
                    child: Text('🧠', style: TextStyle(fontSize: 50)),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Welcome to Luscid!',
                  style: AppTextStyles.heading2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Let\'s get started.\nWho will be using this app?',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                // Role options
                _buildRoleCard(
                  role: UserRole.senior,
                  title: 'I\'m a Senior',
                  subtitle: 'I want to play and keep my mind active',
                  emoji: '👴',
                ),
                const SizedBox(height: 16),
                _buildRoleCard(
                  role: UserRole.caregiver,
                  title: 'I\'m Family/Caregiver',
                  subtitle: 'I want to play with or support a loved one',
                  emoji: '👨‍👩‍👧',
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String subtitle,
    required String emoji,
  }) {
    return GestureDetector(
      onTap: () => _selectRole(role),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.heading4),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinCreation() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isConfirmingPin ? 'Confirm Your PIN' : 'Create Your PIN',
                  style: AppTextStyles.heading2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _isConfirmingPin
                      ? 'Enter the same 4-digit PIN again'
                      : 'Choose a 4-digit PIN you\'ll remember',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Text(
                      _error!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                NumericKeypad(
                  currentValue: _isConfirmingPin ? _confirmPin : _pin,
                  onDigitPressed: _onDigitPressed,
                  onBackspace: _onBackspace,
                  onClear: _onClear,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}
