import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'core/network/api_client.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

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
  // BLoCs are registered as Factory (creates a new instance if needed)
  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(getIt<AuthRepository>()),
  );
}