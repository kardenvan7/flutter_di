import 'package:flutter/widgets.dart';

import 'di_container.dart';

class DiScopeInheritedWidget extends InheritedWidget {
  const DiScopeInheritedWidget({
    required super.child,
    required this.scopeName,
    required this.container,
    super.key,
  });

  final String scopeName;
  final DiContainer container;

  static T getFrom<T>(BuildContext context) =>
      maybeGetFrom(context) ??
      (throw Exception('Type $T is not registered in the given context'));

  static T? maybeGetFrom<T>(BuildContext context) {
    T? something;

    visitScopes(
      context,
      (element) {
        final possibleSomething =
            (element.widget as DiScopeInheritedWidget).container.maybeGet<T>();

        if (possibleSomething != null) {
          something = possibleSomething;
          return false;
        }

        return true;
      },
    );

    return something;
  }

  static Future<T> getAsyncFrom<T>(BuildContext context) async =>
      await maybeGetAsyncFrom<T>(context) ??
      (throw Exception('Type $T is not registered in the given context'));

  static Future<T?> maybeGetAsyncFrom<T>(BuildContext context) async {
    T? something;

    await visitScopesAsync(
      context,
      (element) async {
        final possibleSomething =
            await (element.widget as DiScopeInheritedWidget)
                .container
                .maybeGetAsync<T>();

        if (possibleSomething != null) {
          something = possibleSomething;
          return false;
        }

        return true;
      },
    );

    return something;
  }

  static List<String> getScopeList(BuildContext context) {
    final List<String> scopeList = [];

    visitScopes(
      context,
      (element) {
        scopeList.add((element.widget as DiScopeInheritedWidget).scopeName);
        return true;
      },
    );

    return scopeList.reversed.toList();
  }

  static void visitScopes(
    BuildContext context,
    bool Function(InheritedElement) callback,
  ) {
    InheritedElement? element = _maybeElementOf(context);

    while (element != null && callback(element)) {
      Element? parentElement;

      // Very cheap since we return the first visited element if there is one.
      // Same as Element._parent but _parent is private :(
      element.visitAncestorElements((element) {
        parentElement = element;
        return false;
      });

      if (parentElement == null) return;

      element = _maybeElementOf(parentElement!);
    }
  }

  static Future<void> visitScopesAsync(
    BuildContext context,
    Future<bool> Function(InheritedElement) callback,
  ) async {
    InheritedElement? element = _maybeElementOf(context);

    while (element != null && await callback(element)) {
      Element? parentElement;

      // Very cheap since we return the first visited element if there is one.
      // Same as Element._parent but _parent is private :(
      element.visitAncestorElements((element) {
        parentElement = element;
        return false;
      });

      if (parentElement == null) return;

      element = _maybeElementOf(parentElement!);
    }
  }

  static DiScopeInheritedWidget? _maybeWidgetOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<DiScopeInheritedWidget>();

  static InheritedElement? _maybeElementOf(BuildContext context) =>
      context.getElementForInheritedWidgetOfExactType<DiScopeInheritedWidget>();

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}
