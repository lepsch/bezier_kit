import 'package:bezier_kit/bezier_kit.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    final awesome = Awesome();

    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () {
      expect(awesome.isAwesome, isTrue);
    });
  });
}
