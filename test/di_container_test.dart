import 'package:flutter_di/src/di_container.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(
    'DiContainer tests',
    () {
      DiContainer getUut() => DiContainer();

      test(
        'Factory registration returns new instance',
        () {
          final uut = getUut();

          uut.registerFactory(() => _SimpleClass());

          final instance1 = uut.get<_SimpleClass>();
          final instance2 = uut.get<_SimpleClass>();

          expect(instance1 == instance2, isFalse);
        },
      );

      test(
        'Singleton registration returns same instance',
        () {
          final uut = getUut();

          uut.registerSingleton(_SimpleClass());

          final instance1 = uut.get<_SimpleClass>();
          final instance2 = uut.get<_SimpleClass>();

          expect(instance1 == instance2, isTrue);
        },
      );

      test(
        'Lazy singleton creates instance one time on-demand',
        () {
          final uut = getUut();

          int instancesCreated = 0;

          uut.registerLazySingleton(
            () => _InstantiableClass(() => instancesCreated++),
          );

          expect(instancesCreated, 0);

          uut.get<_InstantiableClass>();

          expect(instancesCreated, 1);

          uut.get<_InstantiableClass>();

          expect(instancesCreated, 1);
        },
      );

      test(
        'Lazy singleton registration returns same instance',
        () {
          final uut = getUut();

          uut.registerLazySingleton(() => _SimpleClass());

          final instance1 = uut.get<_SimpleClass>();
          final instance2 = uut.get<_SimpleClass>();

          expect(instance1 == instance2, isTrue);
        },
      );

      test(
        'Factory async registration returns new instance',
        () async {
          final uut = getUut();

          uut.registerFactoryAsync(
            () async => Future.delayed(
              const Duration(milliseconds: 100),
              () => _SimpleClass(),
            ),
          );

          final instance1 = await uut.getAsync<_SimpleClass>();
          final instance2 = await uut.getAsync<_SimpleClass>();

          expect(instance1 == instance2, isFalse);
        },
      );

      test(
        'Lazy singleton async registration returns same instance',
        () async {
          final uut = getUut();

          uut.registerLazySingletonAsync(
            () async => Future.delayed(
              const Duration(milliseconds: 100),
              () => _SimpleClass(),
            ),
          );

          final instance1 = await uut.getAsync<_SimpleClass>();
          final instance2 = await uut.getAsync<_SimpleClass>();

          expect(instance1 == instance2, isTrue);
        },
      );

      test(
        'Lazy singleton async can be retrieved with get only after first getAsync returns',
        () async {
          final uut = getUut();

          uut.registerLazySingletonAsync(
            () async => Future.delayed(
              const Duration(milliseconds: 100),
              () => _SimpleClass(),
            ),
          );

          expect(uut.get<_SimpleClass>, throwsException);

          await uut.getAsync<_SimpleClass>();

          expect(uut.get<_SimpleClass>(), isInstanceOf<_SimpleClass>());
        },
      );

      test(
        'Singleton is disposed',
        () async {
          final uut = getUut();

          bool isDisposed = false;

          uut.registerSingleton(
            _DisposableClass(() => isDisposed = true),
            dispose: (instance) => instance.dispose(),
          );

          expect(isDisposed, isFalse);

          await uut.dispose();

          expect(isDisposed, isTrue);
        },
      );

      test(
        'Lazy singleton is disposed',
        () async {
          final uut = getUut();

          bool isDisposed = false;

          uut.registerLazySingleton(
            () => _DisposableClass(() => isDisposed = true),
            dispose: (instance) => instance.dispose(),
          );

          // Needed for instance creation
          uut.get<_DisposableClass>();

          expect(isDisposed, isFalse);

          await uut.dispose();

          expect(isDisposed, isTrue);
        },
      );

      test(
        'Lazy singleton async is disposed',
        () async {
          final uut = getUut();

          bool isDisposed = false;

          uut.registerLazySingletonAsync(
            () async => Future.delayed(
              const Duration(milliseconds: 100),
              () => _DisposableClass(() => isDisposed = true),
            ),
            dispose: (instance) => instance.dispose(),
          );

          // Needed for instance creation
          await uut.getAsync<_DisposableClass>();

          expect(isDisposed, isFalse);

          await uut.dispose();

          expect(isDisposed, isTrue);
        },
      );
    },
  );

  group(
    'AsyncDiContainer tests',
    () {
      AsyncDiContainer getUut() => AsyncDiContainer();

      test(
        'Singleton async registration returns same instance',
        () async {
          final uut = getUut();

          await uut.registerSingletonAsync(
            () async => Future.delayed(
              const Duration(milliseconds: 100),
              () => _SimpleClass(),
            ),
          );

          final instance1 = await uut.get<_SimpleClass>();
          final instance2 = await uut.get<_SimpleClass>();

          expect(instance1 == instance2, isTrue);
        },
      );

      test(
        'Singleton async is disposed',
        () async {
          final uut = getUut();

          bool isDisposed = false;

          await uut.registerSingletonAsync(
            () async => Future.delayed(
              const Duration(milliseconds: 100),
              () => _DisposableClass(() => isDisposed = true),
            ),
            dispose: (instance) => instance.dispose(),
          );

          expect(isDisposed, isFalse);

          await uut.dispose();

          expect(isDisposed, isTrue);
        },
      );
    },
  );
}

class _SimpleClass {}

class _InstantiableClass {
  _InstantiableClass(Function callback) {
    callback();
  }
}

class _DisposableClass {
  _DisposableClass(this._disposeCallback);

  final Function _disposeCallback;

  void dispose() => _disposeCallback();
}
