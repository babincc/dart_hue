import 'package:dart_hue/utils/date_time_tool.dart';
import 'package:test/test.dart';

void main() {
  test('dateOnly uses the supplied local date and clears the time', () {
    expect(DateTimeTool.dateOnly(DateTime(2001, 2, 3, 12, 34)),
        DateTime(2001, 2, 3));
  });
  test('dateOnly preserves UTC', () {
    expect(DateTimeTool.dateOnly(DateTime.utc(2001, 2, 3, 12, 34)),
        DateTime.utc(2001, 2, 3));
  });
  group(
    'toHueString',
    () {
      final DateTime dateTime = DateTime(2021, 1, 1, 1, 1, 1, 1, 1);

      test(
        'normal',
        () {
          expect(
            DateTimeTool.toHueString(dateTime),
            '2021-01-01T01:01:01',
          );
        },
      );
    },
  );
}
