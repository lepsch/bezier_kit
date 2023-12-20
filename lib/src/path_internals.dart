//
//  BezierPath.swift
//  BezierKit
//
//  Created by Holmes Futrell on 7/31/18.
//  Copyright © 2018 Holmes Futrell. All rights reserved.
//

import 'package:bezier_kit/src/path.dart';

bool windingCountImpliesContainment(int count, {required PathFillRule using}) {
  switch (using) {
    case PathFillRule.winding:
      return count != 0;
    case PathFillRule.evenOdd:
      return count % 2 != 0;
  }
}
