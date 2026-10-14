import 'package:flutter_test/flutter_test.dart';
import 'package:myglobaldc/application/providers/schedule_provider.dart';
import 'package:myglobaldc/data/services/bacnet_service.dart';
import 'package:myglobaldc/domain/models/schedule.dart';

WeeklySchedule _weekWithMonday(List<ScheduleTransition> transitions) {
  return WeeklySchedule.empty().copyWithDay(
    WeekDay.monday,
    DaySchedule(day: WeekDay.monday, transitions: transitions),
  );
}

void main() {
  group('convertToBacnetWeeklySchedule', () {
    test('keeps the original unsigned tag even if values are 0/1', () {
      final week = _weekWithMonday([
        ScheduleTransition(time: '08:00:00.00', value: 1, type: 'unsigned'),
        ScheduleTransition(time: '18:00:00.00', value: 0, type: 'unsigned'),
      ]);
      // valueType detected as boolean (0/1) must not force the boolean tag
      final result = convertToBacnetWeeklySchedule(week, ScheduleValueType.boolean);
      final tvs = result.days[0].timeValues;
      expect(tvs.map((t) => t.valueTag), [ScheduleValueTag.unsigned, ScheduleValueTag.unsigned]);
      expect(tvs.map((t) => t.value), [1, 0]);
    });

    test('keeps real tag and converts values to double', () {
      final week = _weekWithMonday([
        ScheduleTransition(time: '08:00:00.00', value: 21.5, type: 'real'),
        // New transition from the editor, without type
        ScheduleTransition(time: '12:00:00.00', value: 19),
      ]);
      final result = convertToBacnetWeeklySchedule(week, ScheduleValueType.enumerated);
      final tvs = result.days[0].timeValues;
      expect(tvs[0].valueTag, ScheduleValueTag.real);
      expect(tvs[1].valueTag, ScheduleValueTag.real);
      expect(tvs[1].value, 19.0);
    });

    test('new transitions use the original schedule type as fallback', () {
      final week = _weekWithMonday([
        ScheduleTransition(time: '08:00:00.00', value: 3),
        ScheduleTransition(time: '18:00:00.00', value: null),
      ]);
      final result = convertToBacnetWeeklySchedule(
        week,
        ScheduleValueType.enumerated,
        fallbackType: 'signed',
      );
      final tvs = result.days[0].timeValues;
      expect(tvs[0].valueTag, ScheduleValueTag.signed);
      expect(tvs[1].valueTag, ScheduleValueTag.nullValue);
      expect(tvs[1].value, isNull);
    });

    test('falls back to boolean/enumerated by valueType for unknown types', () {
      final week = _weekWithMonday([
        ScheduleTransition(time: '08:00:00.00', value: 1),
      ]);
      expect(
        convertToBacnetWeeklySchedule(week, ScheduleValueType.boolean).days[0].timeValues[0].valueTag,
        ScheduleValueTag.boolean,
      );
      expect(
        convertToBacnetWeeklySchedule(week, ScheduleValueType.enumerated).days[0].timeValues[0].valueTag,
        ScheduleValueTag.enumerated,
      );
    });

    test('keeps seconds and hundredths of the transition time', () {
      final week = _weekWithMonday([
        ScheduleTransition(time: '08:00:30.50', value: true, type: 'boolean'),
      ]);
      final tv = convertToBacnetWeeklySchedule(week, ScheduleValueType.boolean).days[0].timeValues[0];
      expect(tv.second, 30);
      expect(tv.hundredths, 50);
    });
  });

  group('bacnetStateTextsToScheduleStateTexts', () {
    test('multistate (enumerated) state-text is 1-based', () {
      final texts = bacnetStateTextsToScheduleStateTexts(['Occ', 'Unocc'], ScheduleValueType.enumerated);
      expect(texts.map((t) => t.index), [1, 2]);
    });

    test('boolean keeps 0 = inactive, 1 = active', () {
      final texts = bacnetStateTextsToScheduleStateTexts(['Off', 'On'], ScheduleValueType.boolean);
      expect(texts.map((t) => t.index), [0, 1]);
    });
  });

  group('ScheduleTransition.toV1Json', () {
    test('uses the original type', () {
      final json = ScheduleTransition(time: '08:00:00.00', value: 2, type: 'unsigned').toV1Json();
      expect(json['type'], 'unsigned');
      expect(json['value'], 2);
    });

    test('new int value on a boolean schedule is sent as boolean', () {
      final week = _weekWithMonday([
        ScheduleTransition(time: '08:00:00.00', value: true, type: 'boolean'),
        ScheduleTransition(time: '12:00:00.00', value: 0),
      ]);
      final day = (week.toV1Json()['value'] as List)[0] as Map<String, dynamic>;
      final tvs = day['timeValues'] as List;
      expect(tvs[1], {'time': '12:00:00.00', 'value': false, 'type': 'boolean'});
    });

    test('null value is sent with null type', () {
      final json = ScheduleTransition(time: '18:00:00.00', value: null, type: 'enumerated').toV1Json();
      expect(json['type'], 'null');
      expect(json['value'], isNull);
    });
  });

  group('copyWith can set null', () {
    test('ScheduleTransition / TimeSlot / Schedule', () {
      final t = ScheduleTransition(time: '08:00', value: 1);
      expect(t.copyWith(value: null).value, isNull);
      expect(t.copyWith().value, 1);

      final slot = TimeSlot(startMinutes: 0, endMinutes: 60, value: 1);
      expect(slot.copyWith(value: null).value, isNull);

      final s = Schedule(
        instance: 1,
        objectName: 'S',
        description: 'd',
        weeklySchedule: WeeklySchedule.empty(),
        scheduleDefault: 0,
      );
      expect(s.copyWith(description: null).description, isNull);
      expect(s.copyWith(scheduleDefault: null).scheduleDefault, isNull);
      expect(s.copyWith().description, 'd');
    });
  });
}
