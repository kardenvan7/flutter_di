import 'package:flutter/widgets.dart';

import 'di_scope_inherited_widget.dart';

extension DiBuildContextExt on BuildContext {
  T get<T>() => DiScopeInheritedWidget.getFrom<T>(this);

  T? maybeGet<T>() => DiScopeInheritedWidget.maybeGetFrom<T>(this);

  Future<T> getAsync<T>() => DiScopeInheritedWidget.getAsyncFrom<T>(this);

  Future<T?> maybeGetAsync<T>() =>
      DiScopeInheritedWidget.maybeGetAsyncFrom<T>(this);

  bool isRegistered<T>() => maybeGet<T>() != null;

  List<String> get scopes => DiScopeInheritedWidget.getScopeList(this);
}
