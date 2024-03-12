import 'package:flutter_di/src/di_getter.dart';

import 'di_registrar.dart';

abstract class DiScopeInitializer {
  void initialize(DiRegistrar registrar, DiGetter getter);
}

abstract class AsyncDiScopeInitializer {
  Future<void> initialize(AsyncDiRegistrar registrar, DiGetter getter);
}
