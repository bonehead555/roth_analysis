import 'package:equatable/equatable.dart';
import 'package:roth_analysis/utilities/json_utilities.dart';

/// Base class for all of the xxxINFO calllses created in this project.
/// Insures use of Equatable (used for testing)
/// And forces concrete implementaions to implement a toJsonMap method
abstract class BaseInfo extends Equatable{
  const BaseInfo();
  JsonMap toJsonMap();
}