part of 'di_container.dart';

sealed class _RegisteredEntity<T> {
  T get();

  Future<T> getAsync();
}

abstract interface class _Disposable {
  FutureOr<void> dispose();
}

/// Entity for registering singletons
///
final class _Singleton<T> implements _RegisteredEntity<T>, _Disposable {
  const _Singleton(
    this._instance, {
    FutureOr<void> Function(T)? disposer,
  }) : _disposer = disposer;

  final T _instance;
  final FutureOr<void> Function(T)? _disposer;

  @override
  T get() => _instance;

  @override
  Future<T> getAsync() {
    debugPrint(
      'Type $T is registered as singleton so there is no need to retrieve it with getAsync method.\n'
      'It is more suitable to use get method instead.',
    );
    return Future.sync(() => _instance);
  }

  @override
  FutureOr<void> dispose() => _disposer?.call(_instance);
}

/// Entity for registering factories
///
final class _Factory<T> implements _RegisteredEntity<T> {
  _Factory(this._factory);

  final T Function() _factory;

  @override
  T get() => _factory();

  @override
  Future<T> getAsync() {
    debugPrint(
      'Type $T is registered as factory so there is no need to retrieve it with getAsync method.\n'
      'It is more suitable to use get method instead.',
    );
    return Future.sync(() => _factory());
  }
}

/// Entity for registering lazy singletons
///
final class _LazySingleton<T> implements _RegisteredEntity<T>, _Disposable {
  _LazySingleton(
    this._factory, {
    FutureOr<void> Function(T)? disposer,
  }) : _disposer = disposer;

  final T Function() _factory;
  final FutureOr<void> Function(T)? _disposer;

  T? _instance;
  T _getInstance() {
    return _instance ??= _factory();
  }

  @override
  T get() => _getInstance();

  @override
  Future<T> getAsync() {
    debugPrint(
      'Type $T is registered as lazy singleton so there is no need to retrieve it with getAsync method.\n'
      'It is more suitable to use get method instead.',
    );
    return Future.sync(() => _getInstance());
  }

  @override
  FutureOr<void> dispose() async {
    if (_instance == null) return;
    return _disposer?.call(_instance!);
  }
}

/// Entity for registering asynchronous factories
///
final class _AsyncFactory<T> implements _RegisteredEntity<T> {
  _AsyncFactory(this._factory);

  final Future<T> Function() _factory;

  @override
  T get() => throw Exception(
        'Type $T is registered as asynchronous factory. Use getAsync or maybeGetAsync to retrieve it.',
      );

  @override
  Future<T> getAsync() => _factory();
}

/// Entity for registering lazy asynchronous singletons
///
final class _LazyAsyncSingleton<T>
    implements _RegisteredEntity<T>, _Disposable {
  _LazyAsyncSingleton(
    this._factory, {
    FutureOr<void> Function(T)? disposer,
  }) : _disposer = disposer;

  final Future<T> Function() _factory;
  final FutureOr<void> Function(T)? _disposer;

  T? _instance;
  Future<T> _getInstance() async {
    return _instance ??= await _factory();
  }

  @override
  T get() =>
      _instance ??
      (throw Exception(
        'Type $T is registered as lazy asynchronous singleton and has not been initialized yet.\n'
        'Use getAsync or maybeGetAsync to initialize and retrieve it.\n'
        'After that you will be able to call it with get method\n',
      ));

  @override
  Future<T> getAsync() => _getInstance();

  @override
  FutureOr<void> dispose() async {
    if (_instance == null) return;
    return _disposer?.call(_instance!);
  }
}
