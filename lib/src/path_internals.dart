// Copyright (c) 2023-2024 Guilherme Lepsch. All rights reserved. Use of
// this source code is governed by MIT license that can be found in the
// [LICENSE file](https://github.com/lepsch/bezier_kit/blob/main/LICENSE).

import 'package:bezier_kit/src/path.dart';

bool windingCountImpliesContainment(int count, {required PathFillRule using}) {
  switch (using) {
    case PathFillRule.winding:
      return count != 0;
    case PathFillRule.evenOdd:
      return count % 2 != 0;
  }
}
