//
//  Path+Uint8List.swift
//  BezierKit
//
//  Created by Holmes Futrell on 3/15/19.
//  Copyright © 2019 Holmes Futrell. All rights reserved.
//

import 'dart:math';
import 'dart:typed_data';

import 'package:bezier_kit/src/path.dart';
import 'package:bezier_kit/src/path_component.dart';
import 'package:bezier_kit/src/point.dart';

// extension on Uint8List {
//   void appendNativeValue<U>(U value) {
//     var temp = value;
//     this.add(temp);
//     // withUnsafePointer(to: &temp) { (ptr: UnsafePointer<U>) in
//     //     final bytesSize = MemoryLayout<U>.size
//     //     final bytes: UnsafePointer<UInt8> = UnsafeRawPointer(ptr).bindMemory(to: UInt8.this, capacity: bytesSize);
//     //     this.add(bytes, length: bytesSize);
//     // }
//   }
// }

class _DataStream {
  int dataCursor;
  final Uint8List data;

  _DataStream({required this.data}) : dataCursor = data.offsetInBytes;

  int read(Uint8List buffer, {required int maxLength}) {
    final startIndex = dataCursor;
    final endIndex = min(dataCursor + maxLength, data.length);
    buffer.setRange(0, endIndex - startIndex, data, startIndex);
    final readBytes = endIndex - startIndex;
    dataCursor += readBytes;
    return readBytes;
  }

  bool readNativeValue<T extends TypedData>(T value) {
    final size = value.elementSizeInBytes;
    final buffer = value.buffer.asUint8List(value.offsetInBytes, size);
    return read(buffer, maxLength: size) == size;
  }

  bool readNativeValues<T extends TypedData>(
      {required T to, required int length}) {
    if (length <= 0) return true;
    final size = length * to.elementSizeInBytes;
    final buffer = to.buffer.asUint8List(to.offsetInBytes, size);
    final bytesRead = read(buffer, maxLength: size);
    return bytesRead == size;
  }
}

typedef SerializationTypeMagicNumber = Uint32List;
typedef SerializationTypeCommandCount = Uint32List;
typedef SerializationTypeCommand = Uint8List;
typedef SerializationTypeCoordinate = Float64List;

class _SerializationConstants {
  _SerializationConstants._();
  // just a random number that helps us identify if the data is OK and saved in compatible version
  static const magicNumberVersion1 = 1223013157;
  static const startComponentCommand = 0;
}

mixin PathDataMixin on PathBase {
  static Path? fromData(Uint8List data) {
    final components = <PathComponent>[];
    var stream = _DataStream(data: data);

    // check the magic number
    var magic = Uint32List(1);
    if (!stream.readNativeValue(magic)) return null;
    if (magic.first != _SerializationConstants.magicNumberVersion1) {
      return null;
    }
    final commandCount = SerializationTypeCommandCount(1);
    if (!stream.readNativeValue(commandCount)) return null;
    final commands = SerializationTypeCommand(commandCount.first);
    if (!stream.readNativeValues(to: commands, length: commands.length)) {
      return null;
    }

    // read the commands and coordinates
    var currentPoints = <Point>[];
    var currentOrders = <int>[];
    for (var i = 0; i < commands.length; i++) {
      final command = commands[i];
      var pointsToRead = command;
      if (command == _SerializationConstants.startComponentCommand) {
        if (currentPoints.isEmpty || currentOrders.isNotEmpty) {
          pointsToRead = 1;
        }
        if (currentPoints.isNotEmpty) {
          if (currentOrders.isEmpty) {
            assert(currentPoints.length == 1);
            currentOrders.add(0);
          }
          components
              .add(PathComponent(points: currentPoints, orders: currentOrders));
          currentPoints = [];
          currentOrders = [];
        }
      } else {
        currentOrders.add(pointsToRead);
      }

      final x = SerializationTypeCoordinate(1);
      final y = SerializationTypeCoordinate(1);
      for (var _ = 0; _ < pointsToRead; _++) {
        if (!stream.readNativeValue(x)) return null;
        if (!stream.readNativeValue(y)) return null;
        final point = Point(x: x.first, y: y.first);
        currentPoints.add(point);
      }
    }
    if (currentOrders.isNotEmpty) {
      components
          .add(PathComponent(points: currentPoints, orders: currentOrders));
    }
    return Path(components: components);
  }

  Uint8List get data {
    final expectedCoordinatesCount =
        2 * components.fold<int>(0, ($0, $1) => ($0 + $1.points.length));
    final expectedCommandsCount =
        components.fold<int>(0, ($0, $1) => ($0 + $1.numberOfElements)) +
            components.length;

    // compile the data into a format we can easily serialize
    final commands = <int>[];
    final coordinates = <double>[];
    for (final component in components) {
      coordinates.addAll(component.points.expand(($0) => [$0.x, $0.y]));
      commands.addAll([_SerializationConstants.startComponentCommand]);
      commands.addAll(component.orders);
    }
    assert(expectedCoordinatesCount == coordinates.length);
    assert(expectedCommandsCount == commands.length);

    // serialize the data to object of type `Uint8List`
    final expectedBytesCount = SerializationTypeMagicNumber.bytesPerElement +
        SerializationTypeCommandCount.bytesPerElement +
        SerializationTypeCommand.bytesPerElement * commands.length +
        SerializationTypeCoordinate.bytesPerElement * coordinates.length;
    final result = BytesBuilder(copy: false);
    // write the magicNumber
    result.add(SerializationTypeMagicNumber.fromList(
        [_SerializationConstants.magicNumberVersion1]).buffer.asUint8List());
    // write the commands length
    result.add(SerializationTypeCommandCount.fromList([commands.length])
        .buffer
        .asUint8List());
    // write the commands
    result
        .add(SerializationTypeCommand.fromList(commands).buffer.asUint8List());
    // write the points
    result.add(
        SerializationTypeCoordinate.fromList(coordinates).buffer.asUint8List());
    assert(expectedBytesCount == result.length);

    return result.toBytes();
  }
}
