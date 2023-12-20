extension ListExtensions<T> on List<T> {
  /// if an array has unused capacity returns a new array where `this.count == this.capacity`
  /// can save memory when an array is immutable after adding some initial items
  List<T> get copyByTrimmingReservedCapacity {
    // if (this.capacity > length) return this;
    return [...this];
  }
}
