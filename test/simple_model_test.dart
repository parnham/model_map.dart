part of model_map_test;


class SimpleModel extends ModelMap
{
  String string;
  int integer;
  bool flag;
  num float;
}


class SimpleModelWithDate extends ModelMap
{
  DateTime date;
}


class SimpleModelWithDateSetter extends ModelMap
{
  DateTime date;


  SimpleModelWithDateSetter()
  {
    register('date', (v) => this.date = v);
  }
}


void simpleModelTest()
{
  // Create an ISO 8601 date
  var now   = new DateTime.now();
  var date  = now.toString().replaceFirst(' ', 'T');
  var map   = { 'string': 'some text', 'integer': 42, 'flag': true, 'float': 1.23 };
  var json  = stringify(map);

  group('Simple model:', () {
    test('Assign values from map', () {
      new SimpleModel().fromMap(map).then(expectAsync1((model) {
        expect(model.string, equals('some text'));
        expect(model.integer, equals(42));
        expect(model.flag, equals(true));
        expect(model.float, equals(1.23));
      }));
    });

    test('Extract values to map', () {
      new SimpleModel()
        ..string  = 'some text'
        ..integer = 42
        ..flag    = true
        ..float   = 1.23
        ..toMap().then(expectAsync1((result) => expect(result, equals(map))));
    });
  });

  group('Simple model with date:', () {
    test('Assign date without setter', () {
      expect(() => new SimpleModelWithDate().fromMap({ 'date': date }), throws);
    });

    test('Assign date with setter', () {
     new SimpleModelWithDateSetter().fromMap({ 'date': date }).then(expectAsync1((model) {
       expect(model.date, equals(now));
     }));
    });
  });

  test('Simple model from and to json', () {
    new SimpleModel().fromJson(json).then(expectAsync1((model) {
      model.toJson().then(expectAsync1((result) {
        expect(parse(result), equals(map));
      }));
    }));
  });
}
