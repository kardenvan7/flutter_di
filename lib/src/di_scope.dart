import 'package:flutter/widgets.dart';

import 'context_extensions.dart';
import 'di_scope_initializer.dart';
import 'di_getter.dart';
import 'di_scope_inherited_widget.dart';
import 'di_container.dart';

/// A widget that creates a dependency scope using passed initializer factory
/// in [create] method.
///
/// The context passed in [builder] method can be used to retrieve values from
/// this scope.
///
/// [scopeName] allows for setting custom name for the scope. The list of
/// scopes in the current context starting from closest one can be retrieved
/// via [context.scopes] extension getter.
///
/// [DiScope.fromContainer] constructor is useful for initializing a container
/// outside of UI (most commonly, in [main] function).
class DiScope extends StatefulWidget {
  const DiScope({
    required DiScopeInitializer Function(BuildContext) this.create,
    required this.builder,
    this.scopeName,
    super.key,
  }) : container = null;

  const DiScope.fromContainer({
    required DiContainer this.container,
    required this.builder,
    this.scopeName,
    super.key,
  }) : create = null;

  final DiScopeInitializer Function(BuildContext)? create;
  final DiContainer? container;
  final Widget Function(BuildContext) builder;
  final String? scopeName;

  @override
  State<DiScope> createState() => _DiScopeState();
}

class _DiScopeState extends State<DiScope> {
  late final DiContainer _container;
  late final String _scopeName;

  @override
  void initState() {
    final initializer = widget.create?.call(context);

    if (initializer != null) {
      _container = DiContainer();
      _scopeName = widget.scopeName ?? '${initializer.runtimeType}';
      final contextualGetter =
          _ContextualDiGetterDecorator(context, _container);
      initializer.initialize(_container, contextualGetter);
    } else {
      _container = widget.container!;
      _scopeName = widget.scopeName ??
          '${_container.runtimeType}#${_container.runtimeType}';
    }

    super.initState();
  }

  @override
  void dispose() {
    _container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DiScopeInheritedWidget(
      scopeName: _scopeName,
      container: _container,
      child: Builder(builder: widget.builder),
    );
  }
}

class AsyncDiScope extends StatefulWidget {
  const AsyncDiScope({
    required this.create,
    required this.placeholder,
    required this.builder,
    this.scopeName,
    super.key,
  });

  final AsyncDiScopeInitializer Function(BuildContext) create;
  final Widget placeholder;
  final Widget Function(BuildContext) builder;
  final String? scopeName;

  @override
  State<AsyncDiScope> createState() => _AsyncDiScopeState();
}

class _AsyncDiScopeState extends State<AsyncDiScope> {
  AsyncDiContainer? _container;

  bool get _isInitializing => _container == null;

  String get _scopeName =>
      widget.scopeName ?? '${widget.runtimeType}#${_container.hashCode}';

  @override
  void initState() {
    final container = AsyncDiContainer();
    final contextualGetter = _ContextualDiGetterDecorator(context, container);

    widget
        .create(context)
        .initialize(container, contextualGetter)
        .then((value) => setState(() => _container = container));

    super.initState();
  }

  @override
  void dispose() {
    _container?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) return widget.placeholder;

    return DiScopeInheritedWidget(
      scopeName: _scopeName,
      container: _container!,
      child: Builder(builder: widget.builder),
    );
  }
}

/// A decorator around local getter to allow dependency search in
/// outer scopes if it's not found in the local one.
///
class _ContextualDiGetterDecorator implements DiGetter {
  const _ContextualDiGetterDecorator(this.context, this.localGetter);

  final BuildContext context;
  final DiGetter localGetter;

  @override
  T get<T>() {
    return localGetter.maybeGet<T>() ?? context.get<T>();
  }

  @override
  T? maybeGet<T>() {
    return localGetter.maybeGet<T>() ?? context.maybeGet<T>();
  }

  @override
  bool isRegistered<T>() {
    return localGetter.isRegistered<T>() || context.isRegistered<T>();
  }

  @override
  Future<T> getAsync<T>() async {
    final local = await localGetter.maybeGetAsync<T>();
    if (local != null) return local;

    if (!context.mounted) {
      throw Exception(
        'The context used for retrieving type $T is no longer mounted',
      );
    }

    return context.getAsync<T>();
  }

  @override
  Future<T?> maybeGetAsync<T>() async {
    final local = await localGetter.maybeGetAsync<T>();
    if (local != null) return local;

    if (!context.mounted) return null;

    return context.maybeGetAsync<T>();
  }
}
