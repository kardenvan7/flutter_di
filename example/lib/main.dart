import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_di/flutter_di.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter DI Example',
      showPerformanceOverlay: true,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: const DiExampleWidget(),
      ),
    );
  }
}

class DiExampleWidget extends StatelessWidget {
  const DiExampleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return DiScope(
      create: (_) => _SomeContainer('1'),
      builder: (context) {
        return AsyncDiScope(
          create: (_) => _SomeAsyncScopeInitializer('async 4'),
          placeholder: Center(child: CircularProgressIndicator()),
          builder: (context) {
            return DiScope(
              create: (_) => _SomeContainer('2'),
              scopeName: 'Some2',
              builder: (context) {
                return DiScope(
                  create: (_) => _IgnoredContainer('3'),
                  scopeName: 'Ignored3',
                  builder: (context) {
                    return _ValueReceiverWidget();
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ValueReceiverWidget extends StatefulWidget {
  const _ValueReceiverWidget();

  @override
  State<_ValueReceiverWidget> createState() => _ValueReceiverWidgetState();
}

class _ValueReceiverWidgetState extends State<_ValueReceiverWidget> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Timer.periodic(
        const Duration(milliseconds: 100),
        (timer) => setState(() {}),
      );
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          for (int i = 0; i < 100; i++)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: FutureBuilder(
                future: context.getAsync<_SomeClass3>(),
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data?.someString ??
                        snapshot.error?.toString() ??
                        'Fetching...',
                    style: const TextStyle(color: Colors.black),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SomeClass {
  const _SomeClass(this.someString, this.class2);

  final String someString;
  final _SomeClass2 class2;
}

class _SomeClass2 {
  const _SomeClass2();
}

class _SomeClass3 {
  const _SomeClass3(this.someString);

  final String someString;
}

class _SomeContainer extends DiScopeInitializer {
  _SomeContainer(this.value);

  final String value;

  @override
  void initialize(DiRegistrar registrar, DiGetter getter) {
    registrar
      ..registerFactory<_SomeClass2>(() => _SomeClass2())
      ..registerFactory<_SomeClass>(
        () => _SomeClass(
          value,
          getter.get<_SomeClass2>(),
        ),
      );
  }
}

class _SomeAsyncScopeInitializer implements AsyncDiScopeInitializer {
  const _SomeAsyncScopeInitializer(this.value);

  final String value;

  @override
  Future<void> initialize(AsyncDiRegistrar registrar, DiGetter getter) async {
    await registrar.registerSingletonAsync<_SomeClass3>(
      () => Future.delayed(
        const Duration(milliseconds: 100),
        () => _SomeClass3(value),
      ),
    );

    registrar
      ..registerFactory<_SomeClass2>(() => _SomeClass2())
      ..registerFactory<_SomeClass>(
        () => _SomeClass(value, getter.get<_SomeClass2>()),
      );
  }
}

class _IgnoredContainer extends DiScopeInitializer {
  _IgnoredContainer(this.value);

  final String value;

  @override
  void initialize(DiRegistrar registrar, DiGetter getter) {
    if (!getter.isRegistered<_SomeClass>()) {
      registrar.registerFactory<_SomeClass>(
        () => _SomeClass(value, getter.get<_SomeClass2>()),
      );
    }
  }
}
