import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../bloc/device_bloc.dart';

class DeviceDetailPage extends StatefulWidget {
  final String deviceId;
  const DeviceDetailPage({super.key, required this.deviceId});

  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  @override
  void initState() {
    super.initState();
    // Fetch channels as soon as the page opens!
    context.read<DeviceBloc>().add(LoadDeviceChannels(widget.deviceId));
  }

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
              context.read<DeviceBloc>().add(DeleteDevice(widget.deviceId));
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppTheme.s24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.s24),
                child: Text(
                  'Cameras',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
              const SizedBox(height: AppTheme.s16),

              // Dynamic Channel List replacing the "coming soon" text
              Expanded(
                child: BlocConsumer<DeviceBloc, DeviceState>(
                  listener: (context, state) {
                    if (state is DeviceError) {
                      AppHaptics.error();
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(state.message)));
                    } else if (state is DevicesLoaded) {
                      AppHaptics.success();
                      context.pop();
                    }
                  },
                  builder: (context, state) {
                    if (state is DeviceOperationLoading ||
                        state is DeviceInitial) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppTheme.amber),
                      );
                    }

                    if (state is DeviceChannelsLoaded) {
                      if (state.channels.isEmpty) {
                        return Center(
                          child: Text(
                            "No cameras found.\nEnsure your NVR is online.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.s24,
                        ),
                        itemCount: state.channels.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppTheme.s12),
                        itemBuilder: (context, index) {
                          final channel = state.channels[index];
                          final isOnline = channel['status'] == 'ONLINE';

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            tileColor: Theme.of(context).colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.rMd),
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isOnline
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.videocam,
                                color: isOnline ? Colors.green : Colors.red,
                              ),
                            ),
                            title: Text(
                              channel['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              isOnline ? 'Online' : 'Offline',
                              style: TextStyle(
                                color: isOnline ? Colors.green : Colors.red,
                                fontSize: 12,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              if (isOnline) {
                                AppHaptics.light();
                                // Navigate to the Live View Page!
                                context.push(
                                  '/devices/${widget.deviceId}/channels/${channel['channelId']}/live',
                                  extra: {'channelName': channel['name']},
                                );
                              } else {
                                AppHaptics.error();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Camera is offline"),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
