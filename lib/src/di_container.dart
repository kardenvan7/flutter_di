import 'dart:async';

import 'package:flutter/widgets.dart';

import 'di_getter.dart';
import 'di_registrar.dart';

part 'entities.dart';

class DiContainer implements DiRegistrar, DiGetter {
  DiContainer();

  final Map<Type, _RegisteredEntity> _registeredMap = {};

  @override
  void registerFactory<T>(T Function() callback) {
    _registeredMap[T] = _Factory<T>(callback);
  }

  @override
  void registerLazySingleton<T>(
    T Function() callback, {
    FutureOr Function(T)? dispose,
  }) {
    _registeredMap[T] = _LazySingleton<T>(
      callback,
      disposer: dispose,
    );
  }

  @override
  void registerSingleton<T>(
    T instance, {
    FutureOr Function(T)? dispose,
  }) {
    _registeredMap[T] = _Singleton<T>(
      instance,
      disposer: dispose,
    );
  }

  @override
  void registerFactoryAsync<T>(Future<T> Function() callback) {
    _registeredMap[T] = _AsyncFactory<T>(callback);
  }

  @override
  void registerLazySingletonAsync<T>(
    Future<T> Function() callback, {
    FutureOr Function(T)? dispose,
  }) {
    _registeredMap[T] = _LazyAsyncSingleton<T>(
      callback,
      disposer: dispose,
    );
  }

  @override
  T get<T>() {
    return maybeGet<T>() ??
        (throw Exception('Type $T is not found in the provided factories map'));
  }

  @override
  T? maybeGet<T>() {
    return _registeredMap[T]?.get();
  }

  @override
  Future<T> getAsync<T>() async {
    return await maybeGetAsync<T>() ??
        (throw Exception('Type $T is not found in the provided factories map'));
  }

  @override
  Future<T?> maybeGetAsync<T>() async {
    return _registeredMap[T]?.getAsync() as Future<T?>?;
  }

  bool isRegistered<T>() => _registeredMap[T] != null;

  Future<void> dispose() async {
    await Future.wait(
      _registeredMap.values.whereType<_Disposable>().map(
            (e) async => await e.dispose(),
          ),
    );
    _registeredMap.clear();
  }
}

class AsyncDiContainer extends DiContainer implements AsyncDiRegistrar {
  @override
  Future<void> registerSingletonAsync<T>(
    Future<T> Function() callback, {
    FutureOr Function(T)? dispose,
  }) async {
    final instance = await callback();

    registerSingleton(instance, dispose: dispose);
  }
}
