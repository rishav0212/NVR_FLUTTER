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

class AddDevicePage extends StatefulWidget {
  const AddDevicePage({super.key});

  @override
  State<AddDevicePage> createState() => _AddDevicePageState();
}

class _AddDevicePageState extends State<AddDevicePage> {
  final _idController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppTheme.darkGradient)),
          const NoiseOverlay(),
          SafeArea(
            child: BlocConsumer<DeviceBloc, DeviceState>(
              listener: (context, state) {
                if (state is DeviceError) {
                  AppHaptics.error();
                } else if (state is DeviceFound) {
                  AppHaptics.light();
                  context.push(AppConstants.pinEntryRoute, extra: {
                    'identifier': state.identifier,
                    'deviceName': state.deviceName,
                  });
                } else if (state is DeviceNotFound) {
                  AppHaptics.light();
                  context.push(AppConstants.registerDeviceRoute, extra: state.identifier);
                }
              },
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AnimatedEntrance(
                        delay: Duration(milliseconds: 100),
                        child: AccentHeader(
                          title: 'Add Device',
                          subtitle: 'Enter the Serial Number or MAC address printed on your NVR.',
                        ),
                      ),
                      const SizedBox(height: 40),
                      if (state is DeviceError) ...[
                        ErrorBanner(message: state.message),
                        const SizedBox(height: 16),
                      ],
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 200),
                        child: CustomTextField(
                          controller: _idController,
                          label: 'Device Identifier',
                          prefixIcon: LucideIcons.scanLine,
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ),
                      const SizedBox(height: 32),
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 300),
                        child: PrimaryButton(
                          text: 'Verify Device',
                          isLoading: state is DeviceChecking,
                          onPressed: () {
                            if (_idController.text.trim().isNotEmpty) {
                              AppHaptics.light();
                              context.read<DeviceBloc>().add(
                                CheckDeviceIdentifier(_idController.text.trim()),
                              );
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