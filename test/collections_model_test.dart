part of model_map_test;


class CollectionsModel extends ModelMap
{
  var map   = new Map<String, int>();
  var list  = new List<String>();
}


class UninitialisedCollectionsModel extends ModelMap
{
  Map<String, int> map;
  List<String> list;
}


void collectionsModelTest()
{
  var map = { 'map': { 'first': 42, 'second': 123 }, 'list': [ 'list', 'of', 'strings' ] };

  group('Collections model:', () {
    test('Assign uninitialised collections from map', () {
      new UninitialisedCollectionsModel().fromMap(map).then(expectAsync1((model) {
        expect(model.map, isNull);
        expect(model.list, isNull);
      }));
    });

    test('Assign collections from map', () {
      new CollectionsModel().fromMap(map).then(expectAsync1((model) {
        expect(model.map, equals(map['map']));
        expect(model.list, equals(map['list']));
      }));
    });

    test('Extract collections to map', () {
      new UninitialisedCollectionsModel()
        ..map   = { 'first': 42, 'second': 123 }
        ..list  = [ 'list', 'of', 'strings' ]
        ..toMap().then(expectAsync1((result) => expect(result, equals(map))));
    });
  });
}
