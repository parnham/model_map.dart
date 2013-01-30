part of model_map_test;


class InnerModel extends ModelMap
{
  String string;
  int integer;
}


class UninitialisedOuterModel extends ModelMap
{
  InnerModel inner;
}


class OuterModel extends ModelMap
{
  InnerModel inner = new InnerModel();
}


void recursiveModelTest()
{
  var map = { 'inner': { 'string': 'some text', 'integer': 42 } };


  group('Recursive model:', () {
    test('Assign uninitialised model from map', () {
      new UninitialisedOuterModel().fromMap(map).then(expectAsync1((model) {
        expect(model.inner, isNull);
      }));
    });

    test('Assign model from map', () {
      new OuterModel().fromMap(map).then(expectAsync1((model) {
        expect(model.inner, isNotNull);
        expect(model.inner.string, equals('some text'));
        expect(model.inner.integer, equals(42));
      }));
    });

    test('Extract model to map', () {
      new OuterModel()
          ..inner.string  = 'some text'
          ..inner.integer = 42
          ..toMap().then(expectAsync1((result) => expect(result, equals(map))));
    });
  });
}