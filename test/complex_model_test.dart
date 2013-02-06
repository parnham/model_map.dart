part of model_map_test;


class ComplexModel extends ModelMap
{
  int integer;
  List<SimpleModel> modelList                 = new List<SimpleModel>();
  Map<String, DateTime> dateMap               = new Map<String, DateTime>();
  Map<String, SimpleModel> modelMap           = new Map<String, SimpleModel>();
  Map<String, List<SimpleModel>> modelListMap = new Map<String, List<SimpleModel>>();
}


void complexModelTest()
{
  var now       = new DateTime.now();
  var today     = now.toString().replaceFirst(' ', 'T');
  var tomorrow  = now.add(new Duration(days: 1)).toString().replaceFirst(' ', 'T');
  var map       = {
    'integer':      42,
    'modelList':    [ { 'string': 'a string', 'flag': true }, { 'string': 'another string', 'float': 1.23 } ],
    'dateMap':      { 'Today': today, 'Tomorrow': tomorrow },
    'modelMap':     { 'first': { 'string': 'first model', 'integer': 1 } },
    'modelListMap': { 'first': [ { 'string': 'first model' }, { 'string': 'second model', 'float': 1.23 }] }
  };


  group('Complex model:', () {
    test('Assign model from map', () {
      new ComplexModel().fromMap(map).then(expectAsync1((model) {
        expect(model.integer, equals(42));
        expect(model.modelList.length, equals(2));
        expect(model.modelList[1].float, equals(1.23));
        expect(model.dateMap['Today'], equals(now));
        expect(model.modelMap['first'].integer, equals(1));
        expect(model.modelListMap['first'].length, equals(2));
        expect(model.modelListMap['first'][1].string, equals('second model'));
      }));
    });

    test('Extract model to map', () {
      new ComplexModel()
          ..integer       = 42
          ..modelList     = [
              new SimpleModel()..string = 'a string'..flag = true,
              new SimpleModel()..string = 'another string'..float = 1.23 ]
          ..dateMap       = { 'Today': now, 'Tomorrow': now.add(new Duration(days: 1)) }
          ..modelMap      = { 'first': new SimpleModel()..string = 'first model'..integer = 1 }
          ..modelListMap  = { 'first': [
              new SimpleModel()..string = 'first model',
              new SimpleModel()..string = 'second model'..float = 1.23 ] }
          ..toMap().then(expectAsync1((result) => expect(result, equals(map))));
    });
  });
}
