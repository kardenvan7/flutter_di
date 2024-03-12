import 'dart:async';

abstract interface class DiRegistrar {
  void registerFactory<T>(T Function() callback);

  void registerSingleton<T>(
    T instance, {
    FutureOr Function(T)? dispose,
  });

  void registerLazySingleton<T>(
    T Function() callback, {
    FutureOr Function(T)? dispose,
  });

  void registerFactoryAsync<T>(Future<T> Function() callback);

  void registerLazySingletonAsync<T>(
    Future<T> Function() callback, {
    FutureOr Function(T)? dispose,
  });
}

abstract interface class AsyncDiRegistrar implements DiRegistrar {
  Future<void> registerSingletonAsync<T>(
    Future<T> Function() callback, {
    FutureOr Function(T)? dispose,
  });
}
