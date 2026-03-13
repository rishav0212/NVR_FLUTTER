import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../bloc/device_bloc.dart';

class PinEntryPage extends StatefulWidget {
  final String identifier;
  final String deviceName;
  
  const PinEntryPage({super.key, required this.identifier, required this.deviceName});

  @override
  State<PinEntryPage> createState() => _PinEntryPageState();
}

class _PinEntryPageState extends State<PinEntryPage> {
  final _pinController = TextEditingController();
  final _shakeKey = GlobalKey<ShakeWidgetState>();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (_pinController.text.trim().isNotEmpty) {
      AppHaptics.medium();
      context.read<DeviceBloc>().add(LinkDevice(
        identifier: widget.identifier,
        adminPin: _pinController.text.trim(),
      ));
    } else {
      _shakeKey.currentState?.shake();
      AppHaptics.error();
    }
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
              } else if (state is DeviceLinked) {
                AppHaptics.success();
                context.go('/devices/${state.device.id}'); 
              }
            },
            builder: (context, state) {
              if (state is DevicePinLocked) return _buildLockoutTimer(state.lockedUntil);

              final isLoading = state is DeviceOperationLoading;
              final errorMessage = state is DeviceError 
                  ? state.message + (state.attemptsRemaining != null ? ' (${state.attemptsRemaining} attempts left)' : '')
                  : null;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.s24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppTheme.s48),
                    AnimatedEntrance(
                      delay: Duration.zero,
                      child: Container(
                        width: 52, height: 52,
                        decoration: AppTheme.amberIconBox(context),
                        child: const Icon(Icons.lock_outline_rounded, color: AppTheme.amber, size: 24),
                      ),
                    ),
                    const SizedBox(height: AppTheme.s24),
                    AnimatedEntrance(
                      delay: const Duration(milliseconds: 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Link Device', style: Theme.of(context).textTheme.displaySmall),
                          const SizedBox(height: AppTheme.s6),
                          Text(
                            'Enter the Admin PIN to securely access ${widget.deviceName}.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.s32),
                    AnimatedEntrance(
                      delay: const Duration(milliseconds: 160),
                      child: ShakeWidget(
                        key: _shakeKey,
                        child: AppTextField(
                          controller: _pinController,
                          label: 'Admin PIN',
                          prefixIcon: Icons.password_rounded,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                        ),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: AppTheme.s16),
                      AnimatedEntrance(
                        delay: Duration.zero,
                        child: ErrorBanner(message: errorMessage),
                      ),
                    ],
                    const Spacer(),
                    AnimatedEntrance(
                      delay: const Duration(milliseconds: 240),
                      child: PrimaryButton(
                        label: 'Link to Account',
                        isLoading: isLoading,
                        onPressed: _submit,
                        icon: Icons.link_rounded,
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

  Widget _buildLockoutTimer(DateTime unlockTime) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.s24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.s24),
            decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.lock_clock_rounded, size: 64, color: AppTheme.error),
          ),
          const SizedBox(height: AppTheme.s24),
          Text('Device Locked', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppTheme.s8),
          Text(
            'Too many failed attempts. For security reasons, this NVR has temporarily locked external access.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.s32),
          StreamBuilder(
            stream: Stream.periodic(const Duration(seconds: 1)),
            builder: (context, snapshot) {
              final remaining = unlockTime.difference(DateTime.now());
              if (remaining.isNegative) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.read<DeviceBloc>().add(CheckDeviceIdentifier(widget.identifier));
                });
                return const CircularProgressIndicator(color: AppTheme.amber);
              }
              final mm = remaining.inMinutes.toString().padLeft(2, '0');
              final ss = (remaining.inSeconds % 60).toString().padLeft(2, '0');
              return Text(
                '$mm:$ss',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppTheme.error, 
                  fontFamily: 'monospace',
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}