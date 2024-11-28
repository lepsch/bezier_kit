// Copyright (c) 2023-2024 Guilherme Lepsch. All rights reserved. Use of
// this source code is governed by MIT license that can be found in the
// [LICENSE file](https://github.com/lepsch/bezier_kit/blob/main/LICENSE).

extension ListExtensions<T> on List<T> {
  /// if an array has unused capacity returns a new array where `this.count == this.capacity`
  /// can save memory when an array is immutable after adding some initial items
  List<T> get copyByTrimmingReservedCapacity {
    // if (this.capacity > length) return this;
    return [...this];
  }
}
