import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'core/network/api_client.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/devices/data/repositories/device_repository.dart';
import 'features/devices/presentation/bloc/device_bloc.dart';

final getIt = GetIt.instance;

Future<void> initDi() async {
  // 1. Core Packages
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
  
  getIt.registerLazySingleton<Dio>(() => Dio());

  // 2. Network Layer
  // We pass the global getIt instance into the ApiClient so the interceptor
  // can trigger the AuthBloc's logout event when a 401 occurs.
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(getIt<Dio>(), getIt<FlutterSecureStorage>()),
  );

  // 3. Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(getIt<ApiClient>(), getIt<FlutterSecureStorage>()),
  );

  // 4. BLoCs
  // Since AuthBloc is so central to the app, we create it as a singleton here.
  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(getIt<AuthRepository>()),
  );

  // --- DEVICES ---
  getIt.registerLazySingleton(() => DeviceRepository(getIt<ApiClient>()));
  // Factory ensures a fresh instance per screen for the wizard!
  getIt.registerFactory(() => DeviceBloc(getIt<DeviceRepository>()));
}