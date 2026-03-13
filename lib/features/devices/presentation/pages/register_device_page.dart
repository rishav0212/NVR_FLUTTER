import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_haptics.dart';
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
  final _shakeKey = GlobalKey<ShakeWidgetState>();
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
    FocusScope.of(context).unfocus();
    setState(() => _localError = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_pinController.text != _confirmPinController.text) {
      setState(() => _localError = "PINs do not match");
      AppHaptics.error();
      _shakeKey.currentState?.shake();
      return;
    }

    AppHaptics.medium();
    context.read<DeviceBloc>().add(
      RegisterDevice(
        identifier: widget.identifier,
        name: _nameController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        adminPin: _pinController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: PageBackground(
        child: SafeArea(
          child: BlocConsumer<DeviceBloc, DeviceState>(
            listener: (context, state) {
              if (state is DeviceError) {
                AppHaptics.error();
                _shakeKey.currentState?.shake();
              } else if (state is DeviceRegistered) {
                AppHaptics.success();
                context.pushReplacement(
                  AppConstants.credentialsRoute,
                  extra: state.credentials,
                );
              }
            },
            builder: (context, state) {
              final isLoading = state is DeviceOperationLoading;
              final errorMessage =
                  _localError ?? (state is DeviceError ? state.message : null);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.s24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppTheme.s16),
                    AnimatedEntrance(
                      delay: Duration.zero,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: AppTheme.amberIconBox(context),
                        child: const Icon(
                          Icons.add_to_queue_rounded,
                          color: AppTheme.amber,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.s24),
                    AnimatedEntrance(
                      delay: const Duration(milliseconds: 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Setup NVR',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: AppTheme.s6),
                          Text(
                            'This is a new device. Give it a name and set a secure physical Admin PIN.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.s24),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ShakeWidget(
                          key: _shakeKey,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                if (errorMessage != null) ...[
                                  AnimatedEntrance(
                                    delay: Duration.zero,
                                    child: ErrorBanner(message: errorMessage),
                                  ),
                                  const SizedBox(height: AppTheme.s16),
                                ],
                                AnimatedEntrance(
                                  delay: const Duration(milliseconds: 160),
                                  child: AppTextField(
                                    controller: _nameController,
                                    label: 'Device Name (e.g. Office)',
                                    prefixIcon: Icons.videocam_outlined,
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Name is required'
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.s12),
                                AnimatedEntrance(
                                  delay: const Duration(milliseconds: 240),
                                  child: AppTextField(
                                    controller: _locationController,
                                    label: 'Location (Optional)',
                                    prefixIcon: Icons.location_on_outlined,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.s12),
                                AnimatedEntrance(
                                  delay: const Duration(milliseconds: 320),
                                  child: AppTextField(
                                    controller: _pinController,
                                    label: 'Set Admin PIN (4-8 digits)',
                                    prefixIcon: Icons.password_rounded,
                                    obscureText: true,
                                    keyboardType: TextInputType.number,
                                    validator: (v) => v != null && v.length >= 4
                                        ? null
                                        : 'Min 4 digits',
                                  ),
                                ),
                                const SizedBox(height: AppTheme.s12),
                                AnimatedEntrance(
                                  delay: const Duration(milliseconds: 400),
                                  child: AppTextField(
                                    controller: _confirmPinController,
                                    label: 'Confirm Admin PIN',
                                    prefixIcon: Icons.password_rounded,
                                    obscureText: true,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => _submit(),
                                  ),
                                ),
                                const SizedBox(height: AppTheme.s32),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedEntrance(
                      delay: const Duration(milliseconds: 480),
                      child: PrimaryButton(
                        label: 'Register Device',
                        isLoading: isLoading,
                        onPressed: _submit,
                        icon: Icons.check_circle_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: AppTheme.s32),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
