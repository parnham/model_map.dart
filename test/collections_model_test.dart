part of model_map_test;


class CollectionsModel extends ModelMap
{
	Map<String, int> map;
	List<String> list;
}


void collectionsModelTest()
{
	var map = { 'map': { 'first': 42, 'second': 123 }, 'list': [ 'list', 'of', 'strings' ] };

	group('Collections model:', () {
		test('Assign collections from map', () {
			var model = new CollectionsModel().fromMap(map);

			expect(model.map, equals(map['map']));
			expect(model.list, equals(map['list']));
		});

		test('Extract collections to map', () {
		var model = new CollectionsModel()
			..map	= { 'first': 42, 'second': 123 }
			..list	= [ 'list', 'of', 'strings' ];

			expect(model.toMap(), equals(map));
		});
	});
}
