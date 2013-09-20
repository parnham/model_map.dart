part of model_map_test;


class InnerModel extends ModelMap
{
  String string;
  int integer;
}


class OuterModel extends ModelMap
{
  InnerModel inner;
}


void recursiveModelTest()
{
  var map = { 'inner': { 'string': 'some text', 'integer': 42 } };

  group('Recursive model:', () {
    test('Assign model from map', () {
			var model = new OuterModel().fromMap(map);

			expect(model.inner, isNotNull);
      expect(model.inner.string, equals('some text'));
      expect(model.inner.integer, equals(42));
    });

    test('Extract model to map', () {
			var model = new OuterModel()
				..inner					= new InnerModel()
        ..inner.string  = 'some text'
        ..inner.integer = 42;

			expect(model.toMap(), equals(map));
    });
  });
}