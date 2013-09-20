part of model_map_test;


class SimpleModel extends ModelMap
{
  String string;
  int integer;
  bool flag;
  num float;
	DateTime date;
}


void simpleModelTest()
{
  // Create an ISO 8601 date
  var now   = new DateTime.now();
  var date  = now.toString().replaceFirst(' ', 'T');
  var map   = { 'string': 'some text', 'integer': 42, 'flag': true, 'float': 1.23, 'date': date };
  var json  = stringify(map);

  group('Simple model:', () {
    test('Assign values from map', () {
			var model = new SimpleModel().fromMap(map);

			expect(model.string, equals('some text'));
      expect(model.integer, equals(42));
      expect(model.flag, equals(true));
      expect(model.float, equals(1.23));
			expect(model.date, equals(now));
    });

    test('Extract values to map', () {
			var model = new SimpleModel()
				..string  = 'some text'
	      ..integer = 42
	      ..flag    = true
	      ..float   = 1.23
				..date		= now;

			expect(model.toMap(), equals(map));
    });
  });
}
