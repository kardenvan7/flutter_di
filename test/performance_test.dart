import 'package:flutter/material.dart';
import 'package:flutter_di/flutter_di.dart';
import 'package:flutter_di/src/di_container.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  Future<void> runComparisonTestFor(
    WidgetTester widgetTester,
    int containerCount,
    int scopeCount, {
    bool ignoreLogs = false,
  }) async {
    void log(Object? value) {
      if (ignoreLogs) return;
      print(value);
    }

    const value = 'val';
    final getIt = GetIt.asNewInstance()
      ..registerFactory<_ValueClass1>(() => _ValueClass1(value))
      ..registerFactory<_ValueClass2>(() => _ValueClass2(value));

    Widget flutterDiWidget = Builder(
      builder: (context) {
        final sw = Stopwatch()..start();
        final value = context.get<_ValueClass1>().value;
        sw.stop();
        log('FluDI 1: ${sw.elapsedMicroseconds}');
        final sw2 = Stopwatch()..start();
        final value2 = context.get<_ValueClass2>().value;
        sw2.stop();
        log('FluDI 2: ${sw2.elapsedMicroseconds}');
        return Text(value);
      },
    );

    Widget getItWidget = Builder(
      builder: (context) {
        final sw = Stopwatch()..start();
        final value = getIt.get<_ValueClass1>().value;
        sw.stop();
        log('GetIt 1: ${sw.elapsedMicroseconds}');
        final sw2 = Stopwatch()..start();
        final value2 = getIt.get<_ValueClass2>().value;
        sw2.stop();
        log('GetIt 2: ${sw2.elapsedMicroseconds}');
        return Text(value);
      },
    );

    Widget wrapWithContainersAndScope(Widget widget) {
      final newWidget = _wrapWithContainers(widget, containerCount);
      final anotherNewWidget = _wrapWithEmptyScopes(newWidget, scopeCount - 1);
      return _wrapWithValueScopes(anotherNewWidget, value, 1);
    }

    await widgetTester.pumpWidget(
      MaterialApp(home: wrapWithContainersAndScope(flutterDiWidget)),
    );

    await widgetTester.pumpWidget(
      MaterialApp(home: wrapWithContainersAndScope(getItWidget)),
    );
  }

  group(
    'Comparison with get_it',
    () {
      const containersCount = 1000;

      final variants = _ScopeCountVariants({
        (containersCount, 1),
        (containersCount, 2),
        (containersCount, 5),
        (containersCount, 10),
        (containersCount, 20),
        (containersCount, 100),
        (containersCount, 1000),
      });

      testWidgets(
        'Warm up',
        (widgetTester) => runComparisonTestFor(
          widgetTester,
          1,
          2,
          ignoreLogs: true,
        ),
      );

      testWidgets(
        'Diff depths',
        variant: variants,
        (widgetTester) => runComparisonTestFor(
          widgetTester,
          variants.currentValue!.$1,
          variants.currentValue!.$2,
        ),
      );
    },
  );
}

class _ScopeCountVariants extends ValueVariant<(int, int)> {
  _ScopeCountVariants(super.values);

  @override
  String describeValue((int, int) value) {
    return 'Containers: ${value.$1}, Scopes: ${value.$2}';
  }
}

Widget _wrapWithContainers(Widget widget, int containerCount) {
  Widget widgetToReturn = widget;
  for (int i = 0; i < containerCount; i++) {
    final lastWidget = widgetToReturn;
    widgetToReturn = Container(child: lastWidget);
  }
  return widgetToReturn;
}

Widget _wrapWithEmptyScopes(
  Widget widget,
  int scopesCount,
) {
  Widget widgetToReturn = widget;
  for (int i = 0; i < scopesCount; i++) {
    final lastWidget = widgetToReturn;
    widgetToReturn = DiScope.fromContainer(
      container: _EmptyDiContainer(),
      scopeName: 'Empty scope $i',
      builder: (_) => lastWidget,
    );
  }
  return widgetToReturn;
}

Widget _wrapWithValueScopes(
  Widget widget,
  String value,
  int scopesCount,
) {
  Widget widgetToReturn = widget;
  for (int i = 0; i < scopesCount; i++) {
    final lastWidget = widgetToReturn;
    widgetToReturn = DiScope(
      create: (_) => _ValueDiScopeInitializer(value),
      scopeName: 'Value scope $i',
      builder: (_) => lastWidget,
    );
  }
  return widgetToReturn;
}

class _EmptyDiContainer extends DiContainer {}

class _ValueDiScopeInitializer extends DiScopeInitializer {
  _ValueDiScopeInitializer(this.value);

  final String value;

  @override
  void initialize(DiRegistrar registrar, DiGetter getter) {
    registrar
      ..registerFactory<_ValueClass1>(() => _ValueClass1(value))
      ..registerFactory<_ValueClass2>(() => _ValueClass2(value));
  }
}

class _ValueClass1 {
  const _ValueClass1(this.value);

  final String value;
}

class _ValueClass2 {
  const _ValueClass2(this.value);

  final String value;
}
