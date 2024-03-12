import 'package:flutter/material.dart';
import 'package:flutter_di/flutter_di.dart';
import 'package:flutter_di/src/di_container.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Value is provided',
    (widgetTester) async {
      const textFromDi = 'It works!';
      const stubText = 'No value found';

      final widget = MaterialApp(
        home: DiScope(
          create: (_) => _TestDiContainer(textFromDi),
          builder: (context) {
            final text = context.maybeGet<_SomeValueClass>()?.value;

            return Text(text ?? stubText);
          },
        ),
      );

      await widgetTester.pumpWidget(widget);

      expect(find.text(textFromDi), findsOne);
      expect(find.text(stubText), findsNothing);
    },
  );

  testWidgets(
    'Value is provided from the closest scope',
    (widgetTester) async {
      const textFromOuterScope = 'It works!';
      const textFromInnerScope = 'It works again!';

      final widget = MaterialApp(
        home: DiScope(
          create: (_) => _TestDiContainer(textFromOuterScope),
          builder: (outerContext) => DiScope(
            create: (_) => _TestDiContainer(textFromInnerScope),
            builder: (innerContext) {
              final text = innerContext.get<_SomeValueClass>().value;

              return Text(text);
            },
          ),
        ),
      );

      await widgetTester.pumpWidget(widget);

      expect(find.text(textFromInnerScope), findsOne);
      expect(find.text(textFromOuterScope), findsNothing);
    },
  );

  testWidgets(
    'Value is provided from an outer scope if not found in the closest one',
    (widgetTester) async {
      const textFromOuterScope = 'It works!';

      final widget = MaterialApp(
        home: DiScope(
          create: (_) => _TestDiContainer(textFromOuterScope),
          builder: (outerContext) => DiScope(
            create: (_) => _OtherTestContainer(),
            builder: (middleContext) => SizedBox(
              child: DiScope(
                create: (_) => _OtherTestContainer(),
                builder: (innerContext) {
                  final text = innerContext.get<_SomeValueClass>().value;

                  return Text(text);
                },
              ),
            ),
          ),
        ),
      );

      await widgetTester.pumpWidget(widget);

      expect(find.text(textFromOuterScope), findsOne);
    },
  );

  testWidgets(
    'Value is provided from an asynchronous scope',
    (widgetTester) async {
      const textFromOuterScope = 'It works!';
      const int delayMs = 100;

      final widget = MaterialApp(
        home: AsyncDiScope(
          create: (context) =>
              _AsyncDiScopeInitializer(textFromOuterScope, delayMs),
          placeholder: SizedBox(),
          builder: (context) => SizedBox(
            child: DiScope(
              create: (_) => _OtherTestContainer(),
              builder: (innerContext) {
                final text = innerContext.get<_SomeValueClass>().value;

                return Text(text);
              },
            ),
          ),
        ),
      );

      await widgetTester.pumpWidget(widget);
      await widgetTester.pump(const Duration(milliseconds: delayMs + 100));

      expect(find.text(textFromOuterScope), findsOne);
    },
  );

  testWidgets(
    'Async value is provided from an async scope',
    (widgetTester) async {
      const stubText = 'Stub!';
      const textFromOuterScope = 'It works!';
      const initializingText = 'Initializing...';
      const int delayMs = 100;

      final widget = MaterialApp(
        home: AsyncDiScope(
          create: (context) =>
              _AsyncDiScopeInitializer(textFromOuterScope, delayMs),
          placeholder: const Text(initializingText),
          builder: (context) => SizedBox(
            child: FutureBuilder<_SomeAsyncFactoryClass>(
              future: context.getAsync<_SomeAsyncFactoryClass>(),
              builder: (innerContext, snapshot) {
                final text = snapshot.data?.value ?? stubText;

                return Text(text);
              },
            ),
          ),
        ),
      );

      await widgetTester.pumpWidget(widget);
      // Container initializing
      expect(find.text(initializingText), findsOne);

      await widgetTester.pump(const Duration(milliseconds: delayMs + 100));
      // Container initialized, FutureBuilder started but not received the value yet
      expect(find.text(stubText), findsOne);

      await widgetTester.pump(const Duration(milliseconds: delayMs + 100));

      // FutureBuilder got the value
      expect(find.text(textFromOuterScope), findsOne);
      expect(find.text(initializingText), findsNothing);
      expect(find.text(stubText), findsNothing);
    },
  );

  testWidgets(
    'Value is provided from container given to a scope',
    (widgetTester) async {
      final container = AsyncDiContainer();
      const textFromDi = 'Async prepared value';
      await widgetTester.runAsync(
        () => container.registerSingletonAsync<_SomeValueClass>(
          () => Future.delayed(
            const Duration(milliseconds: 10),
            () => _SomeValueClass(textFromDi),
          ),
        ),
      );
      const stubText = 'No value found';

      final widget = MaterialApp(
        home: DiScope.fromContainer(
          container: container,
          builder: (context) {
            final text = context.maybeGet<_SomeValueClass>()?.value;

            return Text(text ?? stubText);
          },
        ),
      );

      await widgetTester.pumpWidget(widget);

      expect(find.text(textFromDi), findsOne);
      expect(find.text(stubText), findsNothing);
    },
  );
}

class _TestDiContainer extends DiScopeInitializer {
  _TestDiContainer(this.value);

  final String value;

  @override
  void initialize(DiRegistrar registrar, DiGetter getter) {
    registrar.registerSingleton<_SomeValueClass>(_SomeValueClass(value));
  }
}

class _OtherTestContainer extends DiScopeInitializer {
  @override
  void initialize(DiRegistrar registrar, DiGetter getter) {}
}

class _AsyncDiScopeInitializer extends AsyncDiScopeInitializer {
  _AsyncDiScopeInitializer(this.value, this.delayMs);

  final String value;
  final int delayMs;

  @override
  Future<void> initialize(AsyncDiRegistrar registrar, DiGetter getter) async {
    await registrar.registerSingletonAsync<_SomeValueClass>(
      () => Future.delayed(
        Duration(milliseconds: delayMs),
        () => _SomeValueClass(value),
      ),
    );

    registrar.registerFactoryAsync<_SomeAsyncFactoryClass>(
      () => Future.delayed(
        Duration(milliseconds: delayMs),
        () => _SomeAsyncFactoryClass(value),
      ),
    );
  }
}

class _SomeAsyncFactoryClass {
  const _SomeAsyncFactoryClass(this.value);

  final String value;
}

class _SomeValueClass {
  const _SomeValueClass(this.value);

  final String value;
}
