import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../bloc/device_bloc.dart';

/// Phase 2 — Step 2 placeholder for the device detail / live view screen.
///
/// Currently displays a holding state with device ID and a "coming soon" message.
/// Will be replaced with:
///   • Camera grid / live WebRTC stream (Phase 2 Step 2)
///   • Device settings and member management
///   • Playback controls
///
/// Back navigation uses context.go('/home') to clear the device stack entirely
/// (this page is always reached via context.go, not context.push).

class DeviceDetailPage extends StatelessWidget {
  final String deviceId;
  const DeviceDetailPage({super.key, required this.deviceId});

  void _confirmDelete(BuildContext context) {
    AppHaptics.medium();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.rLg),
        ),
        title: Text(
          'Delete Device',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        content: Text(
          'Are you sure you want to remove this NVR? You will lose access to all connected cameras.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Trigger the delete event!
              context.read<DeviceBloc>().add(DeleteDevice(deviceId));
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeviceBloc, DeviceState>(
      listener: (context, state) {
        if (state is DeviceError) {
          AppHaptics.error();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is DevicesLoaded) {
          // After a successful delete, our BLoC automatically fires LoadMyDevices
          // So if we hit DevicesLoaded here, it means the delete finished perfectly!
          AppHaptics.success();
          context.pop(); // Pop back to dashboard
        }
      },
      builder: (context, state) {
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
            actions: [
              if (state is DeviceOperationLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.error,
                      ),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.error,
                  ),
                  onPressed: () => _confirmDelete(context),
                  tooltip: 'Delete Device',
                ),
            ],
          ),
          body: PageBackground(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.s24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppTheme.s48),
                    AnimatedEntrance(
                      delay: Duration.zero,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: AppTheme.amberIconBox(context),
                        child: const Icon(
                          Icons.videocam_rounded,
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
                            'Device Dashboard',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: AppTheme.s6),
                          Text(
                            'ID: $deviceId',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    AnimatedEntrance(
                      delay: const Duration(milliseconds: 160),
                      child: Center(
                        child: Text(
                          'Camera playback and WebRTC implementation\ncoming in Phase 2 Step 2.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
