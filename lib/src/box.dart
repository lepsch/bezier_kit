class Box<T> {
  T value;
  Box(this.value);

  @override
  String toString() => value.toString();
}
