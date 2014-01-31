ModelMap
========

[![Build Status](https://drone.io/github.com/parnham/model_map.dart/status.png)](https://drone.io/github.com/parnham/model_map.dart/latest)

An experiment in using mirrors to convert from a map to a model and vice versa.


Introduction
------------

Mirrors are a way of performing reflection in Dart. This permits an unknown class to
be traversed and information about fields, properties and methods to be extracted, which
is particularly useful if you wish to convert a serialized representation of an object
such as JSON into an actual object instance.

Mirrors are now properly supported in dart2js, so model_map will work even if compiled to
javascript as long as you decorate your entity with @reflectable.

At this stage ModelMap only worries about non-static, public fields and will ignore getters
and setters.


Examples
--------

### Simple model

```dart
import 'package:model_map/model_map.dart';

class SimpleModel extends ModelMap
{
  String string;
  int integer;
  bool flag;
  num float;
}

main()
{
  var map   = { 'string': 'some text', 'integer': 42, 'flag': true, 'float': 1.23 };
  var model = new SimpleModel().fromMap(map);

  // The model is populated and ready to use at this point
}
```

You can also take an existing model and convert it to a map

```dart
// A map of <String, dynamic>
var map = model.toMap();
```


### Using JSON

A couple of utility functions are included that simply wrap fromMap and toMap
using the built-in parse and stringify capabilities so that you can simply call
fromJson and toJson on your model instance.


### Compiling to javascript

Now that dart2js supports enough of the mirror system, ModelMap will work
in a javascript application. One thing to be aware of is that dart2js
performs tree shaking and to ensure that your entities can be mirrored properly
when compiled to javascript you should decorate them with a helper attribute:

```dart
@reflectable
class SimpleModel extends ModelMap
{
  String string;
  int integer;
}
```


### Complex model

ModelMap can support model instances within models, but they must all extend
the ModelMap class. It also handles List and Map collections (maps are limited
to string keys only, since this is all that JSON can use).

```dart
import 'package:model_map/model_map.dart';

class ComplexModel extends ModelMap
{
  int integer;
  SimpleModel simple;
  List<SimpleModel> modelList;
  Map<String, DateTime> dateMap;
  Map<String, SimpleModel> modelMap;
  Map<String, List<SimpleModel>> modelListMap;
}

main()
{
  var json  = getJsonFromServer();
  var model = new ComplexModel().fromJson(json);

  print(model.modelMap['a key'].flag);
}
```

ModelMap should cope with reasonably complex object trees.


### DateTime

When converting to JSON or a map, ModelMap will always convert dates to an ISO 8601 string,
however when parsing a map it will accept an ISO 8601 string or an integer representing
UTC unix time.
