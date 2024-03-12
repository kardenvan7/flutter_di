abstract interface class DiGetter {
  T get<T>();

  T? maybeGet<T>();

  Future<T> getAsync<T>();

  Future<T?> maybeGetAsync<T>();

  bool isRegistered<T>();
}
