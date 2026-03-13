import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/accent_header.dart';
import '../../../../shared/widgets/noise_overlay.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../bloc/device_bloc.dart';

class RegisterDevicePage extends StatefulWidget {
  final String identifier;
  const RegisterDevicePage({super.key, required this.identifier});

  @override
  State<RegisterDevicePage> createState() => _RegisterDevicePageState();
}

class _RegisterDevicePageState extends State<RegisterDevicePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _localError = null);
    if (!_formKey.currentState!.validate()) return;
    
    if (_pinController.text != _confirmPinController.text) {
      setState(() => _localError = "PINs do not match");
      AppHaptics.error();
      return;
    }

    AppHaptics.light();
    context.read<DeviceBloc>().add(RegisterDevice(
      identifier: widget.identifier,
      name: _nameController.text.trim(),
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      adminPin: _pinController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppTheme.darkGradient)),
          const NoiseOverlay(),
          SafeArea(
            child: BlocConsumer<DeviceBloc, DeviceState>(
              listener: (context, state) {
                if (state is DeviceError) {
                  AppHaptics.error();
                } else if (state is DeviceRegistered) {
                  AppHaptics.success();
                  // Critical: Replace the route so they can't go back to this form
                  context.pushReplacement(AppConstants.credentialsRoute, extra: state.credentials);
                }
              },
              builder: (context, state) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        const AnimatedEntrance(
                          delay: Duration(milliseconds: 100),
                          child: AccentHeader(
                            title: 'Setup NVR', 
                            subtitle: 'This is a new device. Give it a name and set a secure physical Admin PIN.'
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (_localError != null || state is DeviceError) ...[
                          ErrorBanner(message: _localError ?? (state as DeviceError).message),
                          const SizedBox(height: 16),
                        ],
                        AnimatedEntrance(
                          delay: const Duration(milliseconds: 200),
                          child: CustomTextField(
                            controller: _nameController,
                            label: 'Device Name (e.g., Office Cameras)',
                            prefixIcon: LucideIcons.camera,
                            validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        AnimatedEntrance(
                          delay: const Duration(milliseconds: 300),
                          child: CustomTextField(
                            controller: _locationController,
                            label: 'Location (Optional)',
                            prefixIcon: LucideIcons.mapPin,
                          ),
                        ),
                        const SizedBox(height: 16),
                        AnimatedEntrance(
                          delay: const Duration(milliseconds: 400),
                          child: CustomTextField(
                            controller: _pinController,
                            label: 'Set Admin PIN (4-8 digits)',
                            prefixIcon: LucideIcons.shieldCheck,
                            isPassword: true,
                            keyboardType: TextInputType.number,
                            validator: (val) => val != null && val.length >= 4 ? null : 'PIN must be at least 4 digits',
                          ),
                        ),
                        const SizedBox(height: 16),
                        AnimatedEntrance(
                          delay: const Duration(milliseconds: 500),
                          child: CustomTextField(
                            controller: _confirmPinController,
                            label: 'Confirm Admin PIN',
                            prefixIcon: LucideIcons.shieldCheck,
                            isPassword: true,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(height: 40),
                        AnimatedEntrance(
                          delay: const Duration(milliseconds: 600),
                          child: PrimaryButton(
                            text: 'Register Device',
                            isLoading: state is DeviceOperationLoading,
                            onPressed: _submit,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}