
library model_map;

import 'dart:json';
import 'dart:async';
import 'dart:mirrors';


/// Function type used to set unusual fields
typedef dynamic FieldSetter(Object value);


/// ModelMap is an experiment with mirrors.
///
/// Since mirrors are not fully implemented at this time and do not yet
/// compile to javascript then this will be of limited use.
///
/// This must use Futures for now, since there is no way of blocking
/// until the internal futures have completed and therefore the contents
/// of the instance cannot be trusted unless the result is a future too.
///
/// There are some limitiations due to the mirror system being unable
/// to set a field with a complex value (anything not String, int, num,
/// double or bool). To get around this (mostly) simply ensure that
/// any fields that are lists, maps or other models are constructed
/// with empty instances already assigned. In this way, ModelMap will
/// be able to recurse into them and they will be populated also.
/// The exceptions to this are as follows:
/// * Date fields since they cannot be assigned with setField and they
/// cannot be modified.
/// * Other classes that do not descend from ModelMap.
/// The can be handled using a custom setter function, see the register
/// function below.
/// These limitations do not affect the getting of fields and so the
/// conversion to a map and subsequent serialisation to JSON does not
/// require special accessor functions.
///
/// Be warned: the core mirror implementation is still in development
/// and so changes to the API may break this library.
abstract class ModelMap
{
  static var _reMap   = new RegExp(r'^.*<(.+),\s*(.+)>$');
  static var _reList  = new RegExp(r'^.*<(.+)>$');
  var _setters        = new Map<String, FieldSetter>();


  /// Registers a setter function with this instance
  ///
  /// For any fields that cannot be assigned via reflection
  /// and cannot be modified, functions can be assigned
  /// to do the job instead. Pass in the [name] of the
  /// field and the corresponding [setter] function.
  /// A good example is the Date type which is partially
  /// handled below, but cannot actually be assigned and
  /// therefore requires a setter function:
  ///
  ///     register('date', (v) => this.date = v);
  ///
  /// which should be placed in the constructor.
  ///
  void register(String name, FieldSetter setter)
  {
    this._setters[name] = setter;
  }


  /// Populates this object from JSON
  ///
  /// A convenience function that converts JSON to a Map using the built
  /// in parse function and the map is handed to fromMap.
  ///
  /// Returns a future that, when complete, contains a reference to this
  Future<dynamic> fromJson(String json)
  {
    return this.fromMap(parse(json));
  }


  /// Populates this object from a Map
  ///
  /// A map is expected to contain string keys throughout that refer to
  /// the names of fields. All simple (primitive) fields are automatically
  /// populated.
  /// Complex fields cannot be assigned via the mirror system and
  /// therefore instances must already have been created and assigned.
  /// Empty Lists and Maps will be filled where possible, and unknown
  /// classes will be populated as long as they also descend from
  /// ModelMap.
  ///
  /// Returns a future that, when complete, contains a reference to this
  Future<dynamic> fromMap(Map<String, dynamic> map)
  {
    var completer = new Completer();
    var im        = reflect(this);
    var variables = im.type.members.values;
    var futures   = new List<Future>();
    var subs      = new List<Future>();

    // The subs local is a list that is populated while the
    // primary futures complete. This is due to the fact
    // that any futures added to the list after the
    // Future.wait will not be monitored.

    for (VariableMirror m in variables.where((m) => m is VariableMirror))
    {
      if (!m.isPrivate && !m.isStatic)
      {
        var n = m.simpleName;

        switch (m.type.simpleName)
        {
          case "String":  if (map[n] is String) futures.add(im.setField(n, map[n]));  break;
          case "int":     if (map[n] is num)    futures.add(im.setField(n, map[n]));  break;
          case "double":  if (map[n] is num)    futures.add(im.setField(n, map[n]));  break;
          case "num":     if (map[n] is num)    futures.add(im.setField(n, map[n]));  break;
          case "bool":    if (map[n] is bool)   futures.add(im.setField(n, map[n]));  break;

          case "Date":
            if (map.containsKey(n))
            {
              if (this._setters.containsKey(n))
              {
                this._setters[n](_parseDate(map[n]));
              }
              else
              {
                throw  "ModelMap: You must register a setter for Date fields since they cannot "
                       "be set by reflection and existing instances cannot be modified";
              }
            }
            // Replace above with this if setField ever supports complex values
            // futures.add(im.setField(n, _parseDate(map[n])));
            break;

          default:
            if (map.containsKey(n))
            {
              if (this._setters.containsKey(n))
              {
                var f = this._setters[n](map[n]);
                if (f is Future) futures.add(f);
              }
              else
              {
                futures.add(im.getField(n).then((i) =>
                    subs.add(this._parseComplex(m.type.simpleName, i, map[n]))
                ));
              }
            }
            break;
        }
      }
    }

    Future.wait(futures).then((f) =>
        Future.wait(subs).then((s) => completer.complete(this))
    );

    return completer.future;
  }


  /// Serializes this object to JSON
  ///
  /// A convenience function that converts a map generated by toMap
  /// to JSON using the built in stringify function.
  ///
  /// Returns a future that, when complete, contains the JSON string
  /// representing this object instance.
  Future<String> toJson()
  {
    return this.toMap().then((m) => stringify(m));
  }


  /// Converts this object to a map
  ///
  /// This object instance is traversed using reflection and the values,
  /// where possible, are copied into a map structure in which the keys
  /// are the field names and the values are JSON friendly. It will only
  /// handle public, non-static fields and any null fields will be left
  /// out entirely. Complex fields that do not descend from ModelMap (with
  /// the exception of lists, maps and dates), will be skipped.
  /// Any maps must have string keys, since a final JSON output will not
  /// support anything else.
  ///
  /// Returns a future that, when complete, contains the map representing
  /// this object instance.
  Future<Map<String, dynamic>> toMap()
  {
    var completer = new Completer();
    var result    = new Map<String, dynamic>();
    var im        = reflect(this);
    var variables = im.type.members.values;
    var futures   = new List<Future>();
    var subs      = new List<Future>();

    for (VariableMirror m in variables.where((m) => m is VariableMirror))
    {
      if (!m.isPrivate && !m.isStatic)
      {
        var name  = m.simpleName;
        var type  = m.type.simpleName;

        futures.add(im.getField(name).then((f) {
            var item = f.reflectee;

            if (item != null)
            {
              subs.add(this._getValue(item).then((value) {
                  if (value != null) result[name] = value;
              }));
            }
        }));
      }
    }

    Future.wait(futures).then((f) =>
        Future.wait(subs).then((s) => completer.complete(result))
    );

    return completer.future;
  }


  // Retrieve all list items and convert to a new JSON friendly
  // list. It will handle dynamic values but any items that
  // cannot be converted to JSON will be skipped.
  Future<List> _getList(List list)
  {
    Completer completer = new Completer();
    List result         = new List();
    var futures         = new List<Future>();

    for (var item in list)
    {
      futures.add(this._getValue(item).then((value) {
        if (value != null) result.add(value);
      }));
    }

    Future.wait(futures).then((f) => completer.complete(result));
    return completer.future;
  }


  // Retrieve all map items (limited to those with string keys) and
  // convert to a new JSON friendly map. It will handle dynamic values
  // but any items that cannot be converted to JSON will be skipped.
  Future<Map> _getMap(Map map)
  {
    Completer completer = new Completer();
    Map result          = new Map();
    var futures         = new List<Future>();

    map.forEach((key, item) {
      if (key is String)
      {
        futures.add(this._getValue(item).then((value) {
          if (value != null) result[key] = value;
        }));
      }
    });

    Future.wait(futures).then((f) => completer.complete(result));
    return completer.future;
  }


  // Determine if a value can be parsed and return a JSON friendly
  // version. This can include lists, maps and any objects that
  // descend from ModelMap.
  Future _getValue(value)
  {
    Completer completer = new Completer();

    if (value is String || value is num || value is bool)
    {
      completer.complete(value);
    }
    else if (value is Date)
    {
      // Use ISO 8601 format for the date
      completer.complete(value.toString().replaceFirst(' ', 'T'));
    }
    else if (value is List)
    {
      this._getList(value).then((list) =>
        completer.complete(list.length > 0 ? list : null)
      );
    }
    else if (value is Map)
    {
      this._getMap(value).then((map) =>
          completer.complete(map.length > 0 ? map : null)
      );
    }
    else if (value is ModelMap)
    {
      value.toMap().then((map) =>
          completer.complete(map.length > 0 ? map : null)
      );
    }
    else completer.complete(null);

    return completer.future;
  }


  // Not really primitive, but what Dart classes as simple types, i.e.,
  // the ones which the mirror system allows you to assign with setField.
  bool _primitive(String type)
  {
    return type == "String" || type == "int" || type == "double" || type == "num" || type == "bool";
  }


  // Attempts to create an item to be added to a list or map. This can handle
  // sub-lists and maps, simple types and any complex types that descend from
  // ModelMap.
  Future _createValue(String type, dynamic value)
  {
    Completer completer = new Completer();

    // If the type is complex then attempt to find its ClassMirror in the current isolate
    // and instantiate a new one. Then if it is descended from ModelMap it can be populated
    // using the from function. Anything else is not handled and null is returned instead.
    if (type.startsWith("List<"))
    {
      if (value is List)
      {
        // Create an empty list and populate it
        this._setList(type, new List(), value).then((list) => completer.complete(list));
      }
      else completer.complete(null);
    }
    else if (type.startsWith("Map<"))
    {
      if (value is Map)
      {
        var m = _reMap.firstMatch(type);

        if (m != null && m[1] == "String")
        {
          // If the key type is String then create a new map and populate it,
          // any other key type is not supported.
          this._setMap(type, new Map(), value).then((map) => completer.complete(map));
        }
        else completer.complete(null);
      }
      else completer.complete(null);
    }
    else switch (type)
    {
      case "String":  completer.complete(value is String ? value : null); break;
      case "int":     completer.complete(value is num ? value : null);    break;
      case "double":  completer.complete(value is num ? value : null);    break;
      case "num":     completer.complete(value is num ? value : null);    break;
      case "bool":    completer.complete(value is bool ? value : false);  break;
      case "Date":    completer.complete(_parseDate(value));              break;
      default:
        // Attempt to create a new instance by looking up its class mirror in the
        // current library. If the instance is descended from ModelMap then it can
        // be recursively populated.
        var cm = currentMirrorSystem().isolate.rootLibrary.classes[type];
        if (cm != null)
        {
          cm.newInstance('', []).then((i) {
            if (i.reflectee is ModelMap)
            {
              i.reflectee.fromMap(value).then((r) => completer.complete(i.reflectee));
            }
            else completer.complete(null);
          });
        }
        else completer.complete(null);
        break;
    }

    return completer.future;
  }


  // Generate a new Date from the supplied value. If the value is an integer then
  // it is assumed to be a UTC representation of millisends since the epoch.
  // If the value is a string it is parsed with the default parser (which will handle
  // ISO 8601 styles dates).
  Date _parseDate(dynamic value)
  {
    if (value is String)  return new Date.fromString(value);
    if (value is int)     return new Date.fromMillisecondsSinceEpoch(value, isUtc: true);

    return null;
  }


  // Attempt to parse a complex field. If it is a ModelMap it can be
  // recursively populated with fromMap. Lists and maps can be filled
  // automatically and anything else is assigned using the _createValue
  // function.
  Future _parseComplex(String type, InstanceMirror im, dynamic value)
  {
    var completer = new Completer();
    var dst       = im.reflectee;

    // For complex types there must already be an instance to populate
    // since setField only supports setting of simple values at this time
    if (dst != null)
    {
      if (dst is ModelMap)
      {
        dst.fromMap(value).then((f) => completer.complete());
      }
      else if (dst is List)
      {
        this._setList(null, dst, value).then((f) => completer.complete());
      }
      else if (dst is Map)
      {
        this._setMap(null, dst, value).then((f) => completer.complete());
      }
      else
      {
        // This is disabled since any simple values will have been assigned,
        // dates are handled separately, lists/maps/ModelMaps are handled
        // above and other complex types cannot be parsed anyway.
        //this._createValue(type, value).then((v) => completer.complete(dst = v));
        completer.complete();
      }
    }
    else completer.complete();

    return completer.future;
  }


  // Populate a map from the map provided. Only maps with string keys are supported.
  // Each of the values is parsed independently meaning they can be different
  // from each other and also be complex types (such as maps, lists or ModelMap
  // based classes).
  Future _setMap(String type, Map dst, Map map)
  {
    var completer = new Completer();

    // The type information for this instance mirror does not seem to provide
    // the actual types used for the key and value. Generics are problematic
    // but maybe this will be fixed in future. For now we have to parse
    // it out of the runtime type string instead.
    var m       = _reMap.firstMatch(type != null ? type : dst.runtimeType.toString());
    var futures = new List<Future>();

    // Only works with maps that have string keys (any other type of map
    // cannot be converted to/from json).
    if (m != null && m[1] == "String")
    {
      map.forEach((k, v) =>
          futures.add(_createValue(m[2], v).then((r) => dst[k] = r))
      );
    }

    Future.wait(futures).then((v) => completer.complete(dst));

    return completer.future;
  }


  // Populate a list from the supplied items.
  // As with maps, each of the values is parsed independently meaning they can
  // be different from each other and also be complex types (such as maps, lists
  // or ModelMap based classes).
  Future _setList(String type, List dst, List items)
  {
    var completer = new Completer();
    var m         = _reList.firstMatch(type != null ? type : dst.runtimeType.toString());
    var futures   = new List<Future>();

    if (m != null)
    {
      for (var i in items)
      {
        futures.add(_createValue(m[1], i).then((r) => dst.add(r)));
      }
    }

    Future.wait(futures).then((v) => completer.complete(dst));

    return completer.future;
  }
}

