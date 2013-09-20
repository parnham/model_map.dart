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

Be warned that mirrors are still being developed and so leading up to the release of
Dart v1.0 there may still be breaking changes that would stop this library from functioning.

Anything based on mirrors can not yet be fully compiled to javascript and so ModelMap is
not recommended for browser application development at the moment.

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
