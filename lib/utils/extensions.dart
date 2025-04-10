// lib/utils/extensions.dart

extension IterableExtensions<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(int index, T item) convert) {
    return Iterable.generate(length, (i) => convert(i, elementAt(i)));
  }
}