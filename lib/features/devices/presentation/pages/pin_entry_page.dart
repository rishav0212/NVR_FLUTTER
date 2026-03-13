import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/accent_header.dart';
import '../../../../shared/widgets/noise_overlay.dart';
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

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
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
                } else if (state is DeviceLinked) {
                  AppHaptics.success();
                  // Go directly to the device detail page, clearing the wizard stack
                  context.go('/devices/${state.device.id}'); 
                }
              },
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 100),
                        child: AccentHeader(
                          title: 'Link Device', 
                          subtitle: 'Enter the Admin PIN to access ${widget.deviceName}.'
                        ),
                      ),
                      const SizedBox(height: 40),
                      if (state is DeviceError) ...[
                        ErrorBanner(
                          message: state.message + 
                            (state.attemptsRemaining != null ? ' (${state.attemptsRemaining} attempts remaining)' : '')
                        ),
                        const SizedBox(height: 16),
                      ],
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 200),
                        child: CustomTextField(
                          controller: _pinController,
                          label: 'Admin PIN',
                          prefixIcon: LucideIcons.lock,
                          isPassword: true,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(height: 32),
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 300),
                        child: PrimaryButton(
                          text: 'Link to Account',
                          isLoading: state is DeviceOperationLoading,
                          onPressed: () {
                            if (_pinController.text.trim().isNotEmpty) {
                              AppHaptics.light();
                              context.read<DeviceBloc>().add(LinkDevice(
                                identifier: widget.identifier,
                                adminPin: _pinController.text.trim(),
                              ));
                            }
                          },
                        ),
                      ),
                    ],
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