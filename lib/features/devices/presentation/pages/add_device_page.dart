import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../bloc/device_bloc.dart';

// IMPORTANT: Ensure you have created this widget file from the previous step.
// It contains the actual mobile_scanner camera overlay logic.
import '../widgets/qr_scanner_sheet.dart';

class AddDevicePage extends StatefulWidget {
  const AddDevicePage({super.key});

  @override
  State<AddDevicePage> createState() => _AddDevicePageState();
}

class _AddDevicePageState extends State<AddDevicePage> {
  final _idController = TextEditingController();
  final _shakeKey = GlobalKey<ShakeWidgetState>();

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  // --- ADDED: Scanner Invocation Method ---
  // What we are doing: We open a bottom sheet containing the camera scanner.
  // Why: To keep the user in the context of the "Add Device" screen without
  // navigating entirely away. Awaiting the result allows us to instantly
  // update the text controller when a QR code is detected.
  Future<void> _openScanner() async {
    AppHaptics.light(); // Provide feedback that the scanner is opening

    final String? scannedCode = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QrScannerSheet(),
    );

    // If the user scanned a code successfully, auto-fill the field
    if (scannedCode != null && mounted) {
      AppHaptics.success();
      setState(() {
        _idController.text = scannedCode;
      });
    }
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (_idController.text.trim().isNotEmpty) {
      AppHaptics.medium();
      context.read<DeviceBloc>().add(
        CheckDeviceIdentifier(_idController.text.trim()),
      );
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
              } else if (state is DeviceFound) {
                AppHaptics.success();
                context.push(
                  AppConstants.pinEntryRoute,
                  extra: {
                    'identifier': state.identifier,
                    'deviceName': state.deviceName,
                  },
                );
              } else if (state is DeviceNotFound) {
                AppHaptics.success();
                context.push(
                  AppConstants.registerDeviceRoute,
                  extra: state.identifier,
                );
              }
            },
            builder: (context, state) {
              final isLoading = state is DeviceChecking;
              final errorMessage = state is DeviceError ? state.message : null;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.s24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppTheme.s48),
                    // Exactly matches Phase 1 Auth Pattern
                    AnimatedEntrance(
                      delay: Duration.zero,
                      // --- ADDED: GestureDetector ---
                      // We wrapped the decorative icon box with a tap detector
                      // so users can tap the big QR icon to open the camera.
                      child: GestureDetector(
                        onTap: _openScanner,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: AppTheme.amberIconBox(context),
                          child: const Icon(
                            Icons.qr_code_scanner_rounded,
                            color: AppTheme.amber,
                            size: 24,
                          ),
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
                            'Add Device',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: AppTheme.s6),
                          // --- UPDATED: Text to reflect the new functionality ---
                          Text(
                            'Enter the Serial Number or scan the QR code printed on your NVR.',
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
                          controller: _idController,
                          label: 'Device Identifier',
                          prefixIcon: Icons.document_scanner_outlined,
                          // --- ADDED: suffixWidget ---
                          // Adding a smaller scan button directly inside the text input
                          // which is standard UX for scannable fields.
                          suffixWidget: IconButton(
                            icon: const Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 20,
                            ),
                            onPressed: _openScanner,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
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
                        label: 'Verify Device',
                        isLoading: isLoading,
                        onPressed: _submit,
                        icon: Icons.arrow_forward_rounded,
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
