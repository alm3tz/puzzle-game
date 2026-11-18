import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_game/levels.dart';

void main() {
  test('500 valid offline stages', () {
    final levels = buildLevels();
    expect(levels.length, 500);
    for (final level in levels) {
      expect(level.question.isNotEmpty, isTrue);
      expect(level.options.length, 4);
      expect(level.options.toSet().length, 4);
      expect(level.correct, inInclusiveRange(0, 3));
    }
    expect(regions.length, 10);
  });
}
