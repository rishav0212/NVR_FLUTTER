import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/device_models.dart';
import '../../data/repositories/device_repository.dart';

// ═════════════════════════════════════════════════════════════════════════════
// EVENTS
// ═════════════════════════════════════════════════════════════════════════════
abstract class DeviceEvent extends Equatable {
  const DeviceEvent();
  @override
  List<Object?> get props => [];
}

class CheckDeviceIdentifier extends DeviceEvent {
  final String identifier;
  const CheckDeviceIdentifier(this.identifier);
  @override
  List<Object?> get props => [identifier];
}

class RegisterDevice extends DeviceEvent {
  final String identifier, name, adminPin;
  final String? location;
  const RegisterDevice({
    required this.identifier,
    required this.name,
    required this.adminPin,
    this.location,
  });
}

class LinkDevice extends DeviceEvent {
  final String identifier, adminPin;
  const LinkDevice({required this.identifier, required this.adminPin});
}

class LoadMyDevices extends DeviceEvent {}

class RefreshDevices extends DeviceEvent {}

class DeleteDevice extends DeviceEvent {
  final String deviceId;
  const DeleteDevice(this.deviceId);
  @override
  List<Object?> get props => [deviceId];
}

/// Loads camera channels for a specific device.
/// Uses an in-memory cache: if channels for this deviceId are already loaded,
/// the event is ignored and the existing [DeviceChannelsLoaded] state is kept.
class LoadDeviceChannels extends DeviceEvent {
  final String deviceId;

  /// Set to true to force a fresh fetch even if channels are cached.
  final bool forceRefresh;

  const LoadDeviceChannels(this.deviceId, {this.forceRefresh = false});

  @override
  List<Object?> get props => [deviceId, forceRefresh];
}

// ═════════════════════════════════════════════════════════════════════════════
// STATES
// ═════════════════════════════════════════════════════════════════════════════
abstract class DeviceState extends Equatable {
  const DeviceState();
  @override
  List<Object?> get props => [];
}

class DeviceInitial extends DeviceState {}

// Wizard States
class DeviceChecking extends DeviceState {}

class DeviceNotFound extends DeviceState {
  final String identifier;
  const DeviceNotFound(this.identifier);
}

class DeviceFound extends DeviceState {
  final String identifier;
  final String deviceName;
  const DeviceFound({required this.identifier, required this.deviceName});
}

class DeviceOperationLoading extends DeviceState {}

// Success States
class DeviceRegistered extends DeviceState {
  final DeviceCredentials credentials;
  const DeviceRegistered(this.credentials);
}

class DeviceLinked extends DeviceState {
  final NvrDevice device;
  const DeviceLinked(this.device);
}

// Dashboard State
class DevicesLoaded extends DeviceState {
  final List<NvrDevice> devices;
  final bool isRefreshing;
  const DevicesLoaded({required this.devices, this.isRefreshing = false});
  @override
  List<Object?> get props => [devices, isRefreshing];
}

/// Emitted after a successful channel fetch.
///
/// Carries [deviceId] as a cache key so the bloc handler knows whether to
/// skip the next [LoadDeviceChannels] for the same device.
class DeviceChannelsLoaded extends DeviceState {
  final List<NvrChannel> channels;
  final String deviceId;

  const DeviceChannelsLoaded({required this.channels, required this.deviceId});

  @override
  List<Object?> get props => [channels, deviceId];
}

// Error & Lockout States
class DeviceError extends DeviceState {
  final String message;
  final int? attemptsRemaining;
  const DeviceError({required this.message, this.attemptsRemaining});
  @override
  List<Object?> get props => [message, attemptsRemaining];
}

class DevicePinLocked extends DeviceState {
  final DateTime lockedUntil;
  const DevicePinLocked(this.lockedUntil);
  @override
  List<Object?> get props => [lockedUntil];
}

// ═════════════════════════════════════════════════════════════════════════════
// BLOC
// ═════════════════════════════════════════════════════════════════════════════
class DeviceBloc extends Bloc<DeviceEvent, DeviceState> {
  final DeviceRepository _repo;

  DeviceBloc(this._repo) : super(DeviceInitial()) {
    on<CheckDeviceIdentifier>(_onCheckDevice);
    on<RegisterDevice>(_onRegisterDevice);
    on<LinkDevice>(_onLinkDevice);
    on<LoadMyDevices>(_onLoadMyDevices);
    on<RefreshDevices>(_onRefreshDevices);
    on<DeleteDevice>(_onDeleteDevice);
    on<LoadDeviceChannels>(_onLoadDeviceChannels);
  }

  Future<void> _onCheckDevice(
    CheckDeviceIdentifier event,
    Emitter<DeviceState> emit,
  ) async {
    emit(DeviceChecking());
    try {
      final result = await _repo.checkDevice(
        event.identifier.trim().toUpperCase(),
      );

      if (result.alreadyLinked) {
        emit(
          const DeviceError(message: "You already have access to this device."),
        );
      } else if (result.exists) {
        emit(
          DeviceFound(
            identifier: event.identifier,
            deviceName: result.deviceName ?? 'Device',
          ),
        );
      } else {
        emit(DeviceNotFound(event.identifier));
      }
    } on DeviceException catch (e) {
      emit(DeviceError(message: e.message));
    } catch (_) {
      emit(
        const DeviceError(
          message: 'Connection failed. Please check your network.',
        ),
      );
    }
  }

  Future<void> _onRegisterDevice(
    RegisterDevice event,
    Emitter<DeviceState> emit,
  ) async {
    emit(DeviceOperationLoading());
    try {
      final creds = await _repo.registerDevice(
        identifier: event.identifier,
        name: event.name,
        location: event.location,
        adminPin: event.adminPin,
      );
      emit(DeviceRegistered(creds));
    } on DeviceException catch (e) {
      emit(DeviceError(message: e.message));
    }
  }

  Future<void> _onLinkDevice(
    LinkDevice event,
    Emitter<DeviceState> emit,
  ) async {
    emit(DeviceOperationLoading());
    try {
      final device = await _repo.linkDevice(
        identifier: event.identifier,
        adminPin: event.adminPin,
      );
      emit(DeviceLinked(device));
    } on DeviceException catch (e) {
      if (e.lockedUntil != null) {
        emit(DevicePinLocked(e.lockedUntil!));
      } else {
        emit(
          DeviceError(
            message: e.message,
            attemptsRemaining: e.attemptsRemaining,
          ),
        );
      }
    }
  }

  Future<void> _onLoadMyDevices(
    LoadMyDevices event,
    Emitter<DeviceState> emit,
  ) async {
    emit(DeviceOperationLoading());
    try {
      final devices = await _repo.getMyDevices();
      emit(DevicesLoaded(devices: devices));
    } on DeviceException catch (e) {
      emit(DeviceError(message: e.message));
    }
  }

  Future<void> _onRefreshDevices(
    RefreshDevices event,
    Emitter<DeviceState> emit,
  ) async {
    if (state is DevicesLoaded) {
      emit(
        DevicesLoaded(
          devices: (state as DevicesLoaded).devices,
          isRefreshing: true,
        ),
      );
    }
    try {
      final devices = await _repo.getMyDevices();
      emit(DevicesLoaded(devices: devices, isRefreshing: false));
    } catch (_) {
      if (state is DevicesLoaded) {
        emit(
          DevicesLoaded(
            devices: (state as DevicesLoaded).devices,
            isRefreshing: false,
          ),
        );
      }
    }
  }

  Future<void> _onDeleteDevice(
    DeleteDevice event,
    Emitter<DeviceState> emit,
  ) async {
    emit(DeviceOperationLoading());
    try {
      await _repo.deleteDevice(event.deviceId);
      add(LoadMyDevices());
    } on DeviceException catch (e) {
      emit(DeviceError(message: e.message));
    }
  }

  /// Loads channels for the given device.
  ///
  /// Cache hit: if the current state is already [DeviceChannelsLoaded] for the
  /// same [deviceId] and [forceRefresh] is false, the event is a no-op.
  /// This prevents redundant network calls when the user navigates back to the
  /// device detail page.
  Future<void> _onLoadDeviceChannels(
    LoadDeviceChannels event,
    Emitter<DeviceState> emit,
  ) async {
    // Cache check — skip if already loaded for the same device
    if (!event.forceRefresh && state is DeviceChannelsLoaded) {
      final cached = state as DeviceChannelsLoaded;
      if (cached.deviceId == event.deviceId) return;
    }

    emit(DeviceOperationLoading());
    try {
      final channels = await _repo.getDeviceChannels(event.deviceId);
      emit(DeviceChannelsLoaded(channels: channels, deviceId: event.deviceId));
    } on DeviceException catch (e) {
      emit(DeviceError(message: e.message));
    } catch (_) {
      emit(
        const DeviceError(
          message: 'Failed to load channels. Please try again.',
        ),
      );
    }
  }
}
