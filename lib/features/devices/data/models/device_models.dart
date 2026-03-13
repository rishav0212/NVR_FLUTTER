import 'package:equatable/equatable.dart';

/// Maps exactly to the Spring Boot DevicePermission enum.
enum DevicePermission {
  viewLiveStream,
  viewPlayback,
  controlPtz,
  manageSettings,
  manageMembers,
  deleteDevice,
  unknown;

  static DevicePermission fromString(String val) {
    switch (val) {
      case 'VIEW_LIVE_STREAM':
        return DevicePermission.viewLiveStream;
      case 'VIEW_PLAYBACK':
        return DevicePermission.viewPlayback;
      case 'CONTROL_PTZ':
        return DevicePermission.controlPtz;
      case 'MANAGE_SETTINGS':
        return DevicePermission.manageSettings;
      case 'MANAGE_MEMBERS':
        return DevicePermission.manageMembers;
      case 'DELETE_DEVICE':
        return DevicePermission.deleteDevice;
      default:
        return DevicePermission.unknown;
    }
  }
}

/// Structured exception to extract backend metadata (like PIN attempts).
class DeviceException implements Exception {
  final String message;
  final int? attemptsRemaining;
  final DateTime? lockedUntil;

  DeviceException({
    required this.message,
    this.attemptsRemaining,
    this.lockedUntil,
  });

  @override
  String toString() => message;
}

/// Represents the physical NVR device.
class NvrDevice extends Equatable {
  final String id;
  final String identifier;
  final String name;
  final String? location;
  final String status;
  final List<DevicePermission> myPermissions;

  const NvrDevice({
    required this.id,
    required this.identifier,
    required this.name,
    this.location,
    required this.status,
    required this.myPermissions,
  });

  // Clean permission check for the UI layer
  bool can(DevicePermission permission) => myPermissions.contains(permission);

  bool get isOnline => status == 'ONLINE';
  bool get isOffline => status == 'OFFLINE';
  bool get isPendingConnection => status == 'PENDING_CONNECTION';

  factory NvrDevice.fromJson(Map<String, dynamic> json) {
    final permsList = (json['myPermissions'] as List<dynamic>?) ?? [];
    return NvrDevice(
      id: json['id'] ?? '',
      identifier: json['identifier'] ?? '',
      name: json['name'] ?? 'Unknown NVR',
      location: json['location'],
      status: json['status'] ?? 'OFFLINE',
      myPermissions: permsList
          .map((e) => DevicePermission.fromString(e.toString()))
          .toList(),
    );
  }

  // Required for seamlessly updating device states (like going ONLINE/OFFLINE via WebSockets)
  NvrDevice copyWith({
    String? id,
    String? identifier,
    String? name,
    String? location,
    String? status,
    List<DevicePermission>? myPermissions,
  }) {
    return NvrDevice(
      id: id ?? this.id,
      identifier: identifier ?? this.identifier,
      name: name ?? this.name,
      location: location ?? this.location,
      status: status ?? this.status,
      myPermissions: myPermissions ?? this.myPermissions,
    );
  }

  @override
  List<Object?> get props => [
    id,
    identifier,
    name,
    location,
    status,
    myPermissions,
  ];
}

/// Response from the /check endpoint to drive the wizard flow.
class DeviceCheckResult extends Equatable {
  final bool exists;
  final bool alreadyLinked;
  final String? deviceName;

  const DeviceCheckResult({
    required this.exists,
    required this.alreadyLinked,
    this.deviceName,
  });

  factory DeviceCheckResult.fromJson(Map<String, dynamic> json) {
    return DeviceCheckResult(
      exists: json['exists'] ?? false,
      alreadyLinked: json['alreadyLinked'] ?? false,
      deviceName: json['name'],
    );
  }

  @override
  List<Object?> get props => [exists, alreadyLinked, deviceName];
}

/// Returned ONLY once during initial registration.
class DeviceCredentials extends Equatable {
  final String deviceId;
  final String sipDeviceId;
  final String sipPassword;
  final String sipServerIp;
  final int sipServerPort;

  const DeviceCredentials({
    required this.deviceId,
    required this.sipDeviceId,
    required this.sipPassword,
    required this.sipServerIp,
    required this.sipServerPort,
  });

  factory DeviceCredentials.fromJson(Map<String, dynamic> json) {
    return DeviceCredentials(
      deviceId: json['deviceId'] ?? '',
      sipDeviceId: json['sipDeviceId'] ?? '',
      sipPassword: json['sipPassword'] ?? '',
      sipServerIp: json['sipServerIp'] ?? '',
      sipServerPort: json['sipServerPort'] ?? 5060,
    );
  }

  @override
  List<Object?> get props => [
    deviceId,
    sipDeviceId,
    sipPassword,
    sipServerIp,
    sipServerPort,
  ];
}
