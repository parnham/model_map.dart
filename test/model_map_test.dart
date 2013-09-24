library model_map_test;

import 'dart:json';
import 'package:unittest/unittest.dart';
import 'package:model_map/model_map.dart';

part 'simple_model_test.dart';
part 'collections_model_test.dart';
part 'recursive_model_test.dart';
part 'complex_model_test.dart';


void main()
{
	simpleModelTest();

	collectionsModelTest();

	recursiveModelTest();

	complexModelTest();
}